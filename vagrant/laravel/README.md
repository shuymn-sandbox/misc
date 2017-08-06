# このVagrantfileを実行して得られる環境

laravelをインストールするための下準備  
(hostsファイルに`192.168.33.10 local.dev`の記述がある前提です)

* CentOS 7
* nginx
* php 7.1
* php-fpm
* mysql 5.7
* composer


# 実行後にやること

laravelのインストール

```
# インストールするディレクトリに移動
cd /var/www
# /var/www/blog というディレクトリにlaravelがインストールされる
composer create-project --prefer-dist laravel/laravel blog
# 以下のディレクトリをnginxから書き込み可能にする
chown o+w -R /var/www/blog/storage
chown o+w -R /var/www/blog/bootstrap/cache
```

# ハマりどころ

プロビジョニングファイルを書いてるときに遭遇したいろんなエラーをまとめました

* nginxのrootディレクトリの所有者がnginxになってない
* nginxのhoge.confファイルの記述が間違ってる
* php-fpmを起動する前にownerとgroupをnginxにしなかった
    * php-fpmの設定が正しいかどうか確認するコマンド`php-fpm -t`
* php-fpm.sock の所有者をnginxにしていない
* 正しいはずなのに というときは使ってるブラウザのキャッシュをクリアしてみる
    * https://utano.jp/entry/2016/07/nginx-and-php-fpm-download-php-file/
* vagrantの共有するフォルダはゲストからパーミッションが変えられない
    * nginxのrootディレクトリにしていたりするとハマりやすくなる

nginxやphp-fpmが上手く動かない，というときは`/var/log/nginx/error.log`や`/var/log/php-fpm/error.log`を見る  
だいたい`Permission denied`でエラーがおきるので，`chmod`や`chown`について調べてディレクトリ・フォルダのパーミッションと仲良くなるとうまくいきます

# 参考

* https://saku.io/configuring-default-php-ini-file/
* http://blog.funxion.jp/266/
* https://readouble.com/laravel/5.3/ja/installation.html
