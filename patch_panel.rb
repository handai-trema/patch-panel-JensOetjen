# Software patch-panel.

$log_mode = false 
class PatchPanel < Trema::Controller
  
  def start(_args)
    @patch = Hash.new { [] }
    @mirror = Hash.new { [] }
    @formercommands = Array.new   
    
    log_mode = false 
    
    logger.info 'PatchPanel started.'
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
  end

  def create_patch(dpid, port_a, port_b)    
    
     if $log_mode == true		
		@formercommands << "create patch with port = #{port_a} and #{port_b} on switch #{dpid}"
		end
    
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] += [port_a, port_b].sort
  end

  def delete_patch(dpid, port_a, port_b)
    
     if $log_mode == true		
		@formercommands << "delete patch with port = #{port_a} and #{port_b} on switch #{dpid}"
		end
    
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid] -= [port_a, port_b].sort
  end
  
  def  activate_log_mode()
    
    $log_mode = true
    
  end
  
  def  deactivate_log_mode()
    
    $log_mode = false
    
  end
    
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

  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end  
end
