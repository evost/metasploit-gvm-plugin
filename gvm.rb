#
# This plugin provides integration with GVM. Written by kost,
# averagesecurityguy and evost.
#
# $Id$
# $Revision$
#
# Distributed under MIT license:
# http://www.opensource.org/licenses/mit-license.php
#

require '~/.msf4/plugins/gvm-gmp.rb'

module Msf
class Plugin::GVM < Msf::Plugin
  class GVMCommandDispatcher
    include Msf::Ui::Console::CommandDispatcher

    def name
      "GVM"
    end

    def commands
      {
        'gvm_help' => "Displays help",
        'gvm_version' => "Display the version of the GVM server",
        'gvm_debug' => "Enable/Disable debugging",
        'gvm_connect' => "Connect to an GVM using GMP",

        'gvm_task_create' => "Create a task (name, comment, target, config)",
        'gvm_task_delete' => "Delete task by ID",
        'gvm_task_list' => "Display list of tasks",
        'gvm_task_start' => "Start task by ID",
        'gvm_task_stop' => "Stop task by ID",
        'gvm_task_pause' => "Pause task by ID",
        'gvm_task_resume' => "Resume task by ID",
        'gvm_task_resume_or_start' => "Resume task or start task by ID",

        'gvm_target_create' => "Create target (name, hosts, comment)",
        'gvm_target_delete' => "Delete target by ID",
        'gvm_target_list' => "Display list of targets",

        'gvm_config_list' => "Quickly display list of configs",

        'gvm_format_list' => "Display list of available report formats",

        'gvm_report_list' => "Display a list of available report formats",
        'gvm_report_delete' => "Delete a report specified by ID",
        'gvm_report_download' => "Save a report to disk",
        'gvm_report_import' => "Import report specified by ID into framework",
      }
    end

    def cmd_gvm_help()
      print_status("gvm_help                  Display this help")
      print_status("gvm_debug                 Enable/Disable debugging")
      print_status("gvm_version               Display the version of the GVM server")
      print_status
      print_status("CONNECTION")
      print_status("==========")
      print_status("gvm_connect               Connects to GVM")
      print_status
      print_status("TARGETS")
      print_status("=======")
      print_status("gvm_target_create         Create target")
      print_status("gvm_target_delete         Deletes target specified by ID")
      print_status("gvm_target_list           Lists targets")
      print_status
      print_status("TASKS")
      print_status("=====")
      print_status("gvm_task_create           Create task")
      print_status("gvm_task_delete           Delete a task and all associated reports")
      print_status("gvm_task_list             Lists tasks")
      print_status("gvm_task_start            Starts task specified by ID")
      print_status("gvm_task_stop             Stops task specified by ID")
      print_status("gvm_task_pause            Pauses task specified by ID")
      print_status("gvm_task_resume           Resumes task specified by ID")
      print_status("gvm_task_resume_or_start  Resumes or starts task specified by ID")
      print_status
      print_status("CONFIGS")
      print_status("=======")
      print_status("gvm_config_list           Lists scan configurations")
      print_status
      print_status("FORMATS")
      print_status("=======")
      print_status("gvm_format_list           Lists available report formats")
      print_status
      print_status("REPORTS")
      print_status("=======")
      print_status("gvm_report_list           Lists available reports")
      print_status("gvm_report_delete         Delete a report specified by ID")
      print_status("gvm_report_import         Imports an GVM report specified by ID")
      print_status("gvm_report_download       Downloads an GVM report specified by ID")
    end

    # Verify the database is connected and usable
    def database?
      if !(framework.db and framework.db.usable)
        return false
      else
        return true
      end
    end

    # Verify there is an active GVM connection
    def gvm?
      if @gvm
        return true
      else
        print_error("No GVM connection available. Please use gvm_connect.")
        return false
      end
    end

    # Verify correct number of arguments and verify -h was not given. Return
    # true if correct number of arguments and help was not requested.
    def args?(args, min=1, max=nil)
      if not max then max = min end
      if (args.length < min or args.length > max or args[0] == "-h")
        return false
      end

      return true
    end

  #--------------------------
  # Basic Functions
  #--------------------------
    def cmd_gvm_debug(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.debug(args[0].to_i)
          print_good(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage:")
        print_status("gvm_debug integer")
      end
    end

    def cmd_gvm_version()
      return unless gvm?

      begin
        ver = @gvm.version_get
        print_good("Using GMP version #{ver}")
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end


  #--------------------------
  # Connection Functions
  #--------------------------
    def cmd_gvm_connect(*args)
      # Is the database configured?
      if not database?
        print_error("No database has been configured.")
        return
      end

      if @gvm then
        @gvm = nil
      end

      # Make sure the correct number of arguments are present.
      if args?(args, 3)

        user, pass, path = args

        begin
          print_status("Connecting to GVM instance at #{path} with username #{user}...")
          gvm = GVMGMP::GVMGMP.new('user' => user, 'password' => pass, 'path' => path)
        rescue GVMGMP::GMPAuthError => e
          print_error("Authentication failed: #{e.reason}")
          return
        rescue GVMGMP::GMPConnectionError => e
          print_error("Connection failed: #{e.reason}")
          return
        end
        print_good("GVM connection successful")
        @gvm = gvm

      else
        print_status("Usage:")
        print_status("gvm_connect username password path")
      end
    end


  #--------------------------
  # Target Functions
  #--------------------------
    def cmd_gvm_target_create(*args)
      return unless gvm?

      if args?(args, 4, 5)
        begin
          if args?(args, 4)
            resp = @gvm.target_create('name' => args[0], 'hosts' => args[1], 'comment' => args[2], 'port_range' => args[3])
          else
            resp = @gvm.target_create('name' => args[0], 'hosts' => args[1], 'comment' => args[2], 'port_list' => args[4])
          end
          print_status(resp)
          cmd_gvm_target_list
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end

      else
        print_status("Usage:")
        print_status("gvm_target_create <name> <hosts> <comment> <port_range>")
        print_status("gvm_target_create <name> <hosts> <comment> 0 <port_list_id>")
      end
    end

    def cmd_gvm_target_delete(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.target_delete(args[0])
          print_status(resp)
          cmd_gvm_target_list
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_target_delete <target_id>")
      end
    end

    def cmd_gvm_target_list(*args)
      return unless gvm?

      begin
        tbl = Rex::Text::Table.new(
              'Columns' => ["ID", "Name", "Hosts", "Max Hosts", "In Use", "Comment"])
        @gvm.target_get_all().each do |target|
          tbl << [ target["id"], target["name"], target["hosts"], target["max_hosts"],
          target["in_use"], target["comment"] ]
        end
        print_good("GVM list of targets")
        print_line
        print_line tbl.to_s
        print_line
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end

  #--------------------------
  # Task Functions
  #--------------------------
    def cmd_gvm_task_create(*args)
      return unless gvm?

      if args?(args, 4)
        begin
          resp = @gvm.task_create('name' => args[0], 'comment' => args[1], 'config' => args[2], 'target'=> args[3])
          print_status(resp)
          cmd_gvm_task_list
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end

      else
        print_status("Usage: gvm_task_create <name> <comment> <config_id> <target_id>")
      end
    end

    def cmd_gvm_task_delete(*args)
      return unless gvm?

      if args?(args, 2)

        # User is required to confirm before deleting task.
        if(args[1] != "ok")
          print_error("Warning: Deleting a task will also delete all reports associated with the ")
          print_error("task, please pass in 'ok' as an additional parameter to this command.")
          return
        end

        begin
          resp = @gvm.task_delete(args[0])
          print_status(resp)
          cmd_gvm_task_list
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_delete <id> ok")
        print_error("This will delete the task and all associated reports.")
      end
    end

    def cmd_gvm_task_list(*args)
      return unless gvm?

      begin
        tbl = Rex::Text::Table.new(
              'Columns' => ["ID", "Name", "Comment", "Status", "Progress"])
        @gvm.task_get_all().each do |task|
          tbl << [ task["id"], task["name"], task["comment"], task["status"], task["progress"] ]
        end
        print_good("GVM list of tasks")
        print_line
        print_line tbl.to_s
        print_line
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end

    def cmd_gvm_task_start(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.task_start(args[0])
          print_status(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_start <id>")
      end
    end

    def cmd_gvm_task_stop(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.task_stop(args[0])
          print_status(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_stop <id>")
      end
    end

    def cmd_gvm_task_pause(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.task_pause(args[0])
          print_status(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_pause <id>")
      end
    end

    def cmd_gvm_task_resume(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.task_resume_paused(args[0])
          print_status(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_resume <id>")
      end
    end

    def cmd_gvm_task_resume_or_start(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.task_resume_or_start(args[0])
          print_status(resp)
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_task_resume_or_start <id>")
      end
    end

  #--------------------------
  # Config Functions
  #--------------------------
    def cmd_gvm_config_list(*args)
      return unless gvm?

      begin
        tbl = Rex::Text::Table.new(
          'Columns' => [ "ID", "Name" ])

        @gvm.config_get_all.each do |config|
          tbl << [ config["id"], config["name"] ]
        end
        print_good("GVM list of configs")
        print_line
        print_line tbl.to_s
        print_line
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end

  #--------------------------
  # Format Functions
  #--------------------------
    def cmd_gvm_format_list(*args)
      return unless gvm?

      begin
        tbl = Rex::Text::Table.new(
              'Columns' => ["ID", "Name", "Extension", "Summary"])
        format_get_all.each do |format|
          tbl << [ format["id"], format["name"], format["extension"], format["summary"] ]
        end
        print_good("GVM list of report formats")
        print_line
        print_line tbl.to_s
        print_line
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end

  #--------------------------
  # Report Functions
  #--------------------------
    def cmd_gvm_report_list(*args)
      return unless gvm?

      begin
        tbl = Rex::Text::Table.new(
              'Columns' => ["ID", "Task Name", "Start Time", "Stop Time"])

        resp = @gvm.report_get_raw

        resp.elements.each("//get_reports_response/report") do |report|
          report_id = report.elements["report"].attributes["id"]
          report_task = report.elements["task/name"].get_text
          report_start_time = report.elements["creation_time"].get_text
          report_stop_time = report.elements["modification_time"].get_text

          tbl << [ report_id, report_task, report_start_time, report_stop_time ]
        end
        print_good("GVM list of reports")
        print_line
        print_line tbl.to_s
        print_line
      rescue GVMGMP::GMPError => e
        print_error(e.to_s)
      end
    end

    def cmd_gvm_report_delete(*args)
      return unless gvm?

      if args?(args)
        begin
          resp = @gvm.report_delete(args[0])
          print_status(resp)
          cmd_gvm_report_list
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_report_delete <id>")
      end
    end

    def cmd_gvm_report_download(*args)
      return unless gvm?

      if args?(args, 4)
        begin
          report = @gvm.report_get_raw("report_id"=>args[0],"format"=>args[1])
          ::FileUtils.mkdir_p(args[2])
          name = ::File.join(args[2], args[3])
          print_status("Saving report to #{name}")
          output = ::File.new(name, "w")
          data = nil
          report.elements.each("//get_reports_response"){|r| data = r.to_s}
          output.puts(data)
          output.close
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_report_download <report_id> <format_id> <path> <report_name>")
      end
    end

    def cmd_gvm_report_import(*args)
      return unless gvm?

      if args?(args, 2)
        begin
          report = @gvm.report_get_raw("report_id"=>args[0],"report_format_id"=>args[1], "details"=>"1")
          data = nil
          report.elements.each("//get_reports_response"){|r| data = r.to_s}
          print_status("Importing report to database.")
          framework.db.import({:data => data})
        rescue GVMGMP::GMPError => e
          print_error(e.to_s)
        end
      else
        print_status("Usage: gvm_report_import <report_id> <format_id>")
        print_status("Only the NBE and XML formats are supported for importing.")
      end
    end



    #--------------------------
    # Format Functions
    #--------------------------
    # Get a list of report formats
    def format_get_all
      begin
        resp = @gvm.gmp_request_xml("<get_report_formats/>")
        if @debug then print resp end

        list = Array.new
        resp.elements.each('//get_report_formats_response/report_format') do |report|
          td = Hash.new
          td["id"] = report.attributes["id"]
          td["name"] = report.elements["name"].text
          td["extension"] = report.elements["extension"].text
          td["summary"] = report.elements["summary"].text
          list.push td
        end
        @formats = list
        return list
      rescue
        raise GMPResponseError
      end
    end

  end # End GVM class

#------------------------------
# Plugin initialization
#------------------------------

  def initialize(framework, opts)
    super
    add_console_dispatcher(GVMCommandDispatcher)
    print_status("Welcome to GVM integration by kost, averagesecurityguy and evost.")
    print_status
    print_status("GVM integration requires a database connection. Once the ")
    print_status("database is ready, connect to the GVM server using gvm_connect.")
    print_status("For additional commands use gvm_help.")
    print_status
    @gvm = nil
    @formats = nil
    @debug = nil
  end

  def cleanup
    remove_console_dispatcher('GVM')
  end

  def name
    "GVM"
  end

  def desc
    "Integrates with the GVM - open source vulnerability management"
  end
end
end
