#!/bin/bash

# 获取当前默认分支（如：main或master）
default_branch=$(git rev-parse --abbrev-ref HEAD)

# 一键创建新分支的函数
create_branch() {
    echo "请输入新分支名称: "
    read new_branch

    # 创建新分支并切换至新分支
    git checkout -b "$new_branch"

    # 推送新分支到所有远程仓库
    remotes=$(git remote)
    for remote in $remotes; do
        git push $remote "$new_branch"
    done

    echo "分支 '$new_branch' 创建成功并已推送到所有远程仓库。"
}

# 一键删除分支的函数
delete_branch() {
    branches=$(git branch | sed 's/* //') # 列出所有分支并去掉当前分支标记

    # 如果只有一个分支，不允许删除
    if [ "$(echo "$branches" | wc -l)" -le 1 ]; then
        echo "当前只有一个分支，不允许删除。"
        return
    fi

    echo "当前分支列表:"
    echo "$branches"

    echo "请输入要删除的分支名称: "
    read branch_to_delete

    # 检查用户输入的分支是否存在
    if ! echo "$branches" | grep -q "$branch_to_delete"; then
        echo "分支 '$branch_to_delete' 不存在。"
        return
    fi

    # 检查是否是默认分支（通常是master或main）
    if [ "$branch_to_delete" == "$default_branch" ]; then
        echo "不允许删除默认分支 '$default_branch'。"
        return
    fi

    # 检查分支是否已合并
    if git branch --merged | grep -q "$branch_to_delete"; then
        echo "分支 '$branch_to_delete' 已合并，可以安全删除。"
    else
        echo "分支 '$branch_to_delete' 未合并，是否需要合并到 '$default_branch'？ [y/n]"
        read merge_choice
        if [ "$merge_choice" == "y" ]; then
            # 合并到默认分支
            git checkout "$default_branch"
            git merge "$branch_to_delete"
            echo "合并完成。"

            # 推送默认分支更新到所有远程仓库
            remotes=$(git remote)
            for remote in $remotes; do
                git push $remote "$default_branch"
            done
        fi
    fi

    # 切换到默认分支
    git checkout "$default_branch"

    # 删除本地分支
    git branch -d "$branch_to_delete"
    echo "本地分支 '$branch_to_delete' 已删除。"

    # 强制删除远程分支
    remotes=$(git remote)
    for remote in $remotes; do
        git push $remote --delete "$branch_to_delete"
    done

    echo "远程分支 '$branch_to_delete' 已删除。"
}

# 主菜单
while true; do
    clear
    echo "请选择一个选项:"
    echo "1) 一键创建新分支"
    echo "2) 一键删除分支"
    echo "3) 退出"

    read choice

    case $choice in
        1)
            create_branch
            ;;
        2)
            delete_branch
            ;;
        3)
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