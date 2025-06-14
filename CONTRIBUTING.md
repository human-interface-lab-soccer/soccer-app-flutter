# 貢献ガイドライン

プロジェクトへの貢献，ありがとうございます！

開発プロセスを円滑に進め，高品質なコードベースを維持するために，以下のガイドラインへのご協力をお願いします．

## 1. はじめに

- 既存課題の確認：作業を始める前に，必ず [Issues](https://github.com/human-interface-lab-soccer/soccer-app-flutter/issues) と既存のPull Requestを確認してください．重複作業を防ぎ，効率的に進めるためです．

## 2. 開発ワークフロー (GitHub フロー)

私たちは **GitHub フロー** を採用しています．基本的な開発の流れは以下のとおりです．

1. **Issueを立てる** : 新機能の開発やバグ修正を行う際は，まず [Issues](https://github.com/human-interface-lab-soccer/soccer-app-flutter/issues) にてIssueを立ててください
    - Issue作成後，Statusは自動的に `Todo` になります
    - Sprint, Priorityは手動で該当する項目を設定してください
2. **Issueにアサイン** : 自分が担当するIssueを，必ず自分にアサインしてください
3. **Featureブランチの作成** : `main` ブランチから作業ブランチを作成します
    - ブランチ命名規則 : `feature/[issue-id]-[feature-name]`
    - 例 : `feature/3-github-contribution-example`
4. **作業の開始** : ブランチを作成し，開発を始めるタイミングでIssueのStatusを `In Progress` に変更してください
5. **Pull Request (PR) の作成** : 作業完了したら，`main` ブランチをターゲットにPull Requestを作成してください
    - レビューの準備ができたら， PRのStatusを `Ready for Review` に変更してください
6. **レビューを受ける** : 作成したPRに対して，チームメンバーからレビューを受けてください
7. **マージ** : レビューが承認され，後述のマージ条件を満たしていることを確認した後， `main` ブランチへマージしてください

## 3. マージするためのルール
Pull Requestが `main` ブランチにマージされるためには，以下の条件を **全て満たす** 必要があります．

1. **1名以上のレビューによる承認** : チームメンバーの誰か1名以上から **Approve** をもらう必要があります
2. **CIが全てパスしていること** : formatの統一やlintチェック，自動テストなど，CIで実行されるすべてのジョブが成功している必要があります

## 4. 注意点
- **こまめなPR作成** : 大量の変更を含むPRは，レビューに時間がかかり，コンフリクトの原因にもなりがちです．**1時間程度のレビューで完結するような単位** で，こまめにPRを作成してください．これにより，レビューも迅速に行え，手戻りも少なくなります．
- **コンフリクトの回避** : 自分の作業ブランチは，定期的に `main` ブランチの最新の状態を取り込んでください．特に，
  
  - **新しく作業を始めるとき**
  - **作業がひと段落したとき**
  - **Pull Requestを出す直前**
  - **他のメンバーが重要な変更をmainにマージしたとき** 
  
  など，できるだけ頻繁に取り込むことで，コンフリクトの発生を最小限に抑えられます．
