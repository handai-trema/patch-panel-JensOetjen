# Report: Patch Panel #

Date: 30.10.2016 <br />
Name: Jens Oetjen <br />
Student Number: 33E16024 <br />

## 1 Introduction ##

In this report I will in which ways I modified the patch-panel-program and explain the code. The translated version of the assignment 
contains three tasks. However, it seems that the first one was already implemented (this information comes from my labmates) and thus I focussed on the other 2 tasks and
implemented a bonus function. This is the first time I use ruby and I have huge problems with how arrays and lists, which do not seem
to exist at all, are handled. For this reason, I used a very basic and very bad style to make it at least work somehow. I tried
to use 2-dimensional arrays. But despite a lot of effort, I could not make it work.

## 2 Function for port mirroring ##

I could not find a definition of "port mirroring" in the slides I have been given. Thus, I resorted to only sources and found
the following definition which I used ("Port mirroring is used on a network switch to send a copy of network packets seen on one switch port to a network monitoring connection on another switch port")

I used the following functions to implement this feature:

Commando-function

```ruby
desc 'Creates a mirror patch'
  arg_name 'dpid source_port monitor_port mirror_port'
  command :create_mirror do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      dpid = args[0].hex
	    source_port = args[1].to_i
      monitor_port =args[2].to_i
      mirror_port = args[3].to_i
		  
      Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
       create_mirror_patch(dpid, source_port, monitor_port, mirror_port)
    end
  end
 ```
Source-function

```ruby
def create_mirror_patch(dpid, source_port, monitor_port,  mirror_port)    
    
    if $log_mode == true		
		@formercommands << "create_mirror_patch with source_port = #{source_port} and monitor_port = #{monitor_port} and mirror_port = #{mirror_port} on switch #{dpid}"
		end
    
    send_flow_mod_delete(dpid, match: Match.new(in_port: source_port))
    send_flow_mod_delete(dpid, match: Match.new(in_port: monitor_port))
    
    create_patch(dpid, source_port, monitor_port)
       
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: source_port),
                      actions: [
                        SendOutPort.new(monitor_port),
                        SendOutPort.new(mirror_port)
                      ])
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: monitor_port),
                      actions: [
                        SendOutPort.new(source_port),
                        SendOutPort.new(mirror_port)
                      ])
    @mirror[dpid] += [source_port, monitor_port, mirror_port]  
            
    return true  
  end   
  ```
  
To my knowledge, mirroring can be described as patching with an additional monitoring port. Therefore, I my function calls
"create patch" function but requires one more argument which defines the monitoring port. The flows are defined in such a way that
the monitor port is also included in the send-out-action. Before the new flows are created, the old flows (if there are any) are 
deleted (I am not sure if this works). The mirror entries are stored in an array.

I will show how that this function works with the following commandos:

```	
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel create 0xabc 1 2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel list 0xabc
PATCHES 
Port 1 is connected to port 2
MIRRORINGS 
LOGGED COMMANDS 
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema send_packets --source host1 --dest host2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema send_packets --source host2 --dest host1
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema show_stats host1
Packets sent:
  192.168.0.1 -> 192.168.0.2 = 1 packet
Packets received:
  192.168.0.2 -> 192.168.0.1 = 1 packet
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema show_stats host3
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel create_mirror 0xabc 1 2 3
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel list 0xabc
PATCHES 
Port 1 is connected to port 2
Port 1 is connected to port 2
MIRRORINGS 
Traffic from port 1 to port 2 is mirrored to port 3
LOGGED COMMANDS 
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema send_packets --source host1 --dest host2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# trema show_stats host3
Packets received:
  192.168.0.1 -> 192.168.0.2 = 1 packet
 ```
 
Host 3 did not receive packages when the mirror function was not yet activated. However, it started receiving functions after it had
been activated.

## 3 List of patches and port mirrors ##

I think the version I created does work more or less despite the horrible style. After I gave up on 2-dimensional arrays, I resorted
to loop through the arrays with modulo in my desperation. It is certainly not pretty but it seems to work.
In the following, I present the code:

Commando-function

```ruby
desc 'Prints patch and mirror patch'
  arg_name 'dpid datalist patch mirror_patch'
  command :list do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      dpid = args[0].hex
      datalist = Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
        list_patch(dpid)
      @output = datalist[0]
      @output_mirror = datalist[1]
      @loggedcommands = datalist[2]
        
		counter = 0.0
      
      print ("PATCHES")
	
    @output[dpid].each do |port|

      counter = counter +1

      if counter % 2 == 0		
        print(" is connected to port ", port, "\n")

      else		
      print ("Port ")
      print (port)
		
		end
   end
      
      counter = 0.0
    
    print ("MIRRORINGS")
	
      @output_mirror[dpid].each do |port|
		
      if counter % 3 == 0		
        print("Traffic from port ", port, "")		
      end

      if counter % 3 == 1		
        print(" to port ", port, "")		
      end
        
       if counter % 3 == 2		
		     print(" is mirrored to port ", port, "\n")		
      end
        
       counter = counter +1        		
		  end     
            
     print ("LOGGED COMMANDS")
    
      @loggedcommands.each do |message|
				print("", message, "\n")
	
      end
     end
  end
```
Source-function

```ruby
def list_patch(dpid)    
    
     if $log_mode == true		
		@formercommands << "list on switch #{dpid}"
		end
    
    list = Array.new()
    list << @patch
    list << @mirror
    list << @formercommands
   
    return list
  end
```

With modulo I loop through the arrays for patches, mirrors and logged commandos. Logged commandos come from the bonus function which I 
explain in the next step:


## 4 Bonus function (Logging) ##

As an additional function I implented the ability to log commandos. This function can be activated with log start and deactivated with log stop. 
The following code snippets make this work:

```ruby
desc 'Activates Logging mode'
  arg_name ''
  command :log_start do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      
      Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
         activate_log_mode()
    end
  end
 ``` 
 
 ```ruby
def  activate_log_mode()
    
    $log_mode = true
    
  end
 ```
 
 ```ruby
desc 'Deactivates Logging mode'
  arg_name ''
  command :log_stop do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      
      Trema.trema_process('PatchPanel', options[:socket_dir]).controller.
         deactivate_log_mode()
    end
  end
 ```
 
 ```ruby
def  deactivate_log_mode()
    
    $log_mode = false
    
  end
 ``` 
When the log mode is activated, a copy of the executed commandos is saved in an array. The list function can be used to retrieve
the commandos. In the following, I present a example in which I used some commandos:

```ruby
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel create 0xabc 1 2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel delete 0xabc 1 2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel create_mirror 0xabc 1 2 3
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel list 0xabc
PATCHES 
Port 1 is connected to port 2
MIRRORINGS 
Traffic from port 1 to port 2 is mirrored to port 3
Traffic from port 1 to port 2 is mirrored to port 3
LOGGED COMMANDS 
create patch with port = 1 and 2 on switch 2748
create patch with port = 1 and 2 on switch 2748
delete patch with port = 1 and 2 on switch 2748
create_mirror_patch with source_port = 1 and monitor_port = 2 and mirror_port = 3 on switch 2748
create patch with port = 1 and 2 on switch 2748
list on switch 2748
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel delete 0xabc 1 2
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel list 0xabc
PATCHES 
MIRRORINGS 
Traffic from port 1 to port 2 is mirrored to port 3
Traffic from port 1 to port 2 is mirrored to port 3
LOGGED COMMANDS 
create patch with port = 1 and 2 on switch 2748
create patch with port = 1 and 2 on switch 2748
delete patch with port = 1 and 2 on switch 2748
create_mirror_patch with source_port = 1 and monitor_port = 2 and mirror_port = 3 on switch 2748
create patch with port = 1 and 2 on switch 2748
list on switch 2748
delete patch with port = 1 and 2 on switch 2748
list on switch 2748
root@Jens-Oetjen-PC:/home/jens/Desktop/lesson3/patch-panel-JensOetjen/patch_panel# ./bin/patch_panel list 0xabc
PATCHES 
MIRRORINGS 
Traffic from port 1 to port 2 is mirrored to port 3
Traffic from port 1 to port 2 is mirrored to port 3
LOGGED COMMANDS 
create patch with port = 1 and 2 on switch 2748
create patch with port = 1 and 2 on switch 2748
delete patch with port = 1 and 2 on switch 2748
create_mirror_patch with source_port = 1 and monitor_port = 2 and mirror_port = 3 on switch 2748
create patch with port = 1 and 2 on switch 2748
list on switch 2748
delete patch with port = 1 and 2 on switch 2748
list on switch 2748
list on switch 2748
 ```

To make it work I needed another host and it had to be able to read packets that were not addressed to it. Therefore, it had to be
started in promicious mode. The following trema.conf file was used:
	
```ruby
vswitch('patch') {
  datapath_id '0xabc'
}

vhost ('host1') {
  ip '192.168.0.1'
}

vhost ('host2') {
  ip '192.168.0.2'
}

vhost ('host3') { 
  ip '192.168.0.3' 
  promisc true
}

link 'patch', 'host1'
link 'patch', 'host2'
link 'patch', 'host3'
 ```
	
