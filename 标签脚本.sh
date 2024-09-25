#!/bin/bash

# 获取当前远程仓库列表
remotes=$(git remote)

# 一键创建标签的函数
create_tag() {
    echo "请选择要创建的标签类型:"
    echo "1) 轻量级标签"
    echo "2) 附带签名的标签"
    read tag_type

    echo "请输入标签名称: "
    read tag_name

    if [ "$tag_type" == "1" ]; then
        git tag "$tag_name"
        echo "轻量级标签 '$tag_name' 创建成功。"
    elif [ "$tag_type" == "2" ]; then
        echo "请输入标签信息: "
        read tag_message
        git tag -a "$tag_name" -m "$tag_message"
        echo "附带签名的标签 '$tag_name' 创建成功。"
    else
        echo "无效选项。"
        return
    fi

    # 推送标签到所有远程仓库
    for remote in $remotes; do
        git push $remote "$tag_name"
    done

    echo "标签 '$tag_name' 已推送到所有远程仓库。"
}

# 一键删除指定标签的函数
delete_tag() {
    tags=$(git tag)

    # 如果没有标签，不允许删除
    if [ -z "$tags" ]; then
        echo "当前不存在标签，不允许删除。"
        return
    fi

    echo "当前标签列表:"
    echo "$tags"

    echo "请输入要删除的标签名称: "
    read tag_to_delete

    # 检查用户输入的标签是否存在
    if ! echo "$tags" | grep -q "$tag_to_delete"; then
        echo "标签 '$tag_to_delete' 不存在。"
        return
    fi

    # 删除本地标签
    git tag -d "$tag_to_delete"
    echo "本地标签 '$tag_to_delete' 已删除。"

    # 强制删除远程标签
    for remote in $remotes; do
        git push $remote --delete "$tag_to_delete"
    done

    echo "远程标签 '$tag_to_delete' 已删除。"
}

# 查看标签的函数
view_tags() {
    echo "请选择要查看的标签类型:"
    echo "1) 查看本地标签"
    echo "2) 查看远程标签"
    read view_type

    if [ "$view_type" == "1" ]; then
        local_tags=$(git tag)
        if [ -z "$local_tags" ]; then
            echo "当前无本地标签。"
            return
        fi

        echo "本地标签列表:"
        echo "$local_tags"

        echo "是否查看某一标签的详细信息？ [y/n]"
        read detail_choice
        if [ "$detail_choice" == "y" ]; then
            echo "请输入要查看详细信息的标签名称: "
            read tag_to_view

            if git show "$tag_to_view" &>/dev/null; then
                git show "$tag_to_view"
            else
                echo "标签 '$tag_to_view' 不存在。"
            fi
        fi

    elif [ "$view_type" == "2" ]; then
        echo "当前远程仓库列表:"
        echo "$remotes"

        echo "请输入要查看的远程仓库名称: "
        read remote_to_view

        if ! echo "$remotes" | grep -q "$remote_to_view"; then
            echo "远程仓库 '$remote_to_view' 不存在。"
            return
        fi

        remote_tags=$(git ls-remote --tags "$remote_to_view")
        if [ -z "$remote_tags" ]; then
            echo "远程仓库 '$remote_to_view' 无标签。"
            return
        fi

        echo "远程标签列表:"
        echo "$remote_tags"
    else
        echo "无效选项。"
    fi
}

# 主菜单
while true; do
    clear
    echo "请选择一个选项:"
    echo "1) 一键创建标签"
    echo "2) 一键删除标签"
    echo "3) 查看标签"
    echo "4) 退出"

    read choice

    case $choice in
        1)
            create_tag
            ;;
        2)
            delete_tag
            ;;
        3)
            view_tags
            ;;
        4)
            break
            ;;
        *)
            echo "无效选项。请重试。"
            ;;
    esac

    # 等待用户按任意键继续
    echo "按任意键继续..."
    read -n 1 -s
done