#
# Author:: Dhanesh Raghavan (<dhanesh_r@live.com>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../resource"

class Chef
  class Resource
    class AptUpdate < Chef::Resource
      unified_mode true

      provides :apt_unattended_upgrades, platform_family: "debian", target_mode: true

      description "Use **apt_unattended_upgrades** to auto update the security updates, apt packages on debian systems"        
      
      property :name, String, default: ""

      default_action :enable
      allowed_action :enable, :disable

      property :type,  [String],
        description: "Describes what types of upgrade it should enable automatically eg: security, updates, proposed, backports",
        default: "security"
      
      property :email, [String],
        description: "Describe to which the email need to be send.",
        default: "root"
      
      property :remove_unused_dependencies, [TrueClass, FalseClass],
        description: "Auto remove unused dependencies.",
        default: "false"
      
      property :auto_reboot, [TrueClass, FalseClass],
        description: "Set auto reboot.",
        default: "false"

      property :package_lists_update_frequency, Integer,
      description: "Frequency at which package list update.",
      default: 0
      
      property :unattended_upgrade_frequency, Integer,
        description: "Frequency at which unattended upgrade update.",
        default: 1
      
      property :download_upgradeable_packages, Integer,
        description: "Upgradable package download frequency.",
        default: 0
      
      property :auto_clean_interval, Integer,
      description: "Auto clean interval.",
      default: 0

      property :package_blacklist, String,
      description: ""

      action_class do
        UA_FILE_CONFIG = "/etc/apt/apt.conf.d/50unattended-upgrades"
        UF_FILE_CONFIG = "/etc/apt/apt.conf.d/20auto-upgrades"
        
        def enable_unattended_upgrade(type)
          if ::File.exist?("#{UA_FILE_CONFIG}")
            file "#{UA_FILE_CONFIG}" do
              content "\"${distro_id}:${distro_codename}-#{type}\";"
              owner 'root'
              group 'root'
            end
          end 
        end

        def enable_mail
          if ::File.exist?("#{UA_FILE_CONFIG}")
            file "#{UA_FILE_CONFIG}" do
            content "Unattended-Upgrade::Mail \"#{new_resource.mail}"\";"
            end
          end
        end
        
        def auto_reboot
          if ::File.exist?("#{UA_FILE_CONFIG}")
            file "#{UA_FILE_CONFIG}" do
              content "Unattended-Upgrade::Automatic-Reboot "\"#{new_resource.auto_reboot}\";"
            end
          end
        end
        
        def package_lists_update_frequency
          if ::File.exist?("#{UF_FILE_CONFIG}")
            file "#{UF_FILE_CONFIG}" do
              content "APT::Periodic::Update-Package-Lists\"#{new_resource.package_lists_update_frequency}\";"
            end
          end
        end

        def unattended_upgrade_frequency
          if ::File.exist?("#{UF_FILE_CONFIG}")
            file "#{UF_FILE_CONFIG}" do
              content  "APT::Periodic::Unattended-Upgrade \"#{new_resource.unattended_upgrade_frequency}\";"
            end
          end
        end
        
        def download_upgradeable_packages
          if ::File.exist?("#{UF_FILE_CONFIG}")
            file "#{UF_FILE_CONFIG}" do
              content  "APT::Periodic::Download-Upgradeable-Packages \"#{new_resource.download_upgradeable_packages}\";"
            end
          end
        end 

        def auto_clean_interval
          if ::File.exist?("#{UF_FILE_CONFIG}")
            file "#{UF_FILE_CONFIG}" do
              content  "APT::Periodic::AutocleanInterval \"#{new_resource.auto_clean_interval}\";"
            end
          end
        end 

        action :enable do
          return unless debian?
          
            enable_unattended_upgrade(new_resource.type)
            enable_mail
            auto_reboot
            package_lists_update_frequency
            unattended_upgrade_frequency
            download_upgradeable_packages
            auto_clean_interval
          end 
        end

        action :disable do
          execute "Disabling" do
            command "sed 's/^/#/' \"#{UA_FILE_CONFIG}\""
            command "sed 's/^/#/' \"#{UF_FILE_CONFIG}\""
          end
        end
      end
    end
  end  
end 