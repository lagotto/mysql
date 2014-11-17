module MysqlCookbook
  module Helpers
    module Rhel
      def base_dir
        return "/opt/rh/#{scl_name}/root" if scl_package?
        nil
      end

      def error_log
        "#{base_dir}/var/log/#{mysql_name}/error.log"
      end

      def etc_dir
        "#{base_dir}/etc/#{mysql_name}"
      end

      def include_dir
        "#{etc_dir}/conf.d"
      end

      def mysql_install_db_script
        if scl_package?
          <<-EOF
          scl enable #{scl_name} \
          "mysql_install_db --datadir=#{new_resource.parsed_data_dir} --defaults-file=#{etc_dir}/my.cnf"
          EOF
        else
          <<-EOF
          mysql_install_db --datadir=#{new_resource.parsed_data_dir} --defaults-file=#{etc_dir}/my.cnf
          EOF
        end
      end

      def mysql_safe_init_cmd
        if scl_package?
          "scl enable #{scl_name} \"#{mysqld_safe_bin} --defaults-file=#{etc_dir}/my.cnf --init-file=/tmp/mein.sql &\""
        else
          "#{mysqld_safe_bin} --defaults-file=#{etc_dir}/my.cnf --init-file=/tmp/mein.sql &"
        end
      end

      def init_records_script
        <<-EOS
        set -e
        cat > /tmp/mein.sql <<-EOSQL
DELETE FROM mysql.user ;
CREATE USER 'root'@'%' IDENTIFIED BY 'ilikerandompasswords' ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
FLUSH PRIVILEGES;
DROP DATABASE IF EXISTS test ;
EOSQL

       #{mysql_safe_init_cmd}
       while [ ! -f #{pid_file} ] ; do sleep 1 ; done
       kill `cat #{pid_file}`
       while [ -f #{pid_file} ] ; do sleep 1 ; done
       EOS
      end

      def mysql_bin
        "#{base_dir}/usr/bin/mysql"
      end

      def mysql_name
        "mysql-#{new_resource.parsed_instance}"
      end

      def mysql_version
        new_resource.parsed_version
      end

      def mysqld_bin
        "#{base_dir}/usr/sbin/mysqld"
      end

      def mysqld_safe_bin
        "#{base_dir}/usr/bin/mysqld_safe"
      end

      def pid_file
        "#{run_dir}/mysql.pid"
      end

      def platform_and_version
        case node['platform_family']
        when 'rhel'
          "rhel-#{node['platform_version'].to_i}"
        end
      end

      def prefix_dir
        "#{base_dir}/usr"
      end

      def run_dir
        "#{base_dir}/var/run/#{mysql_name}"
      end

      def scl_name
        if node['platform_version'].to_i == 5
          return 'mysql51' if new_resource.parsed_version == '5.1'
          return 'mysql55' if new_resource.parsed_version == '5.5'
        end
        nil
      end

      def scl_package?
        if node['platform_version'].to_i == 5
          return true if new_resource.parsed_version == '5.1'
          return true if new_resource.parsed_version == '5.5'
        end
        false
      end

      def socket_file
        "#{run_dir}/#{mysql_name}.sock"
      end

      def sysvinit_template
        return 'sysvinit/rhel/scl-sysvinit.erb' if scl_package?
        'sysvinit/rhel/sysvinit.erb'
      end
    end
  end
end
