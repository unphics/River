
/**
 * 常用api:
 *  1. 路径操作类
 *      fs::path p = "dir/file.txt"     构造路径对象
 *      p /= "subdir"                   追加路径元素(类似/操作符)
 *      p.filename()                    返回文件名
 *      p.stem()                        返回不带扩展名的文件名
 *      p.extension()                   返回扩展名
 *      p.parent_path()                 返回父目录路径
 *      p.is_absolute()                 是否为绝对路径
 *      p.is_relative()                 是否为相对路径
 *      fs::absolute(p)                 将相对路径转换为绝对路径
 *      fs::canonical(p)                返回规范化的绝对路径(解析符号链接he./..)
 *      u8string() / string()           转换为utf8或本地编码字符串
 *  2. 文件状态与属性查询
 *      fs::exits(p)                判断路径是否存在
 *      fs::is_directory(p)         是否为目录
 *      fs::is_regular_file(p)      是否是普通文件
 *      fs::is_symlink(p)           是否是符号链接
 *      fs::file_size(p)            获取文件大小
 *      fs::last_write_time(p)      获取最后修改时间(返回fs::time_type)
 *      fs::status(p)               获取文件状态(权限,类型等)
 *      fs::space(p)                获取所在分区的空间信息(总容量/可用/空闲)
 *  3. 目录迭代(遍历文件夹)
 *      fs::directory_iterator                          遍历单层目录
 *      fs::recursive_directory_iterator                递归遍历所有子目录
 *      for (auto& entry : fs::directory_iterator(p))   遍历入口, entry是fs::directory_entry对象
 *      entry.path()                                    获取当前条目的完整路径
 *      entry.is_directory() / is_regular_file()        判断条目类型
 *  4. 文件操作(创建/复制/移动/删除)
 *      fs::create_directory(p)                         创建单级目录
 *      fs::create_directories(p)                       递归创建多级目录(类似mkdir -p)
 *      fs::copy(src, dst)                              复制文件或目录(默认复制文件, 需配合选项)
 *      fs::copy_file(src, dst)                         仅复制文件内容
 *      fs::copy_symlink(src, dst)                      复制符号链接本身
 *      fs::rename(old, new)                            重命名/移动文件或目录
 *      fs::remove(p)                                   删除单个文件或空目录
 *      fs::remove_all(p)                               递归删除目录及其所有内容
 *      fs::create_symlink(target, link)                创建符号链接
 *      fs::create_hardlink(existing, new)              创建硬链接
 *  5. 文件读写辅助(非直接文件IO, 但配合流使用)
 *      fs::open(fs::path, std::ios::mode)              返回std::fstream(cpp标准库文件流可直接接受path参数)
 *      fs::read_symlink(p)                             读取符号链接指向的目录路径
 *      fs::temp_directory_path()                       返回系统临时目录路径
 *      fs::current_path()                              获取/设置当前工作目录
 */

#ifndef File_FileSystem_hh
#define File_FileSystem_hh

#ifdef __cpp_lib_filesystem
#include <filesystem>
namespace fs = ::std::filesystem;
#else
#include "filesystem.hpp"
namespace fs = ::ghc::filesystem;
#endif

#endif