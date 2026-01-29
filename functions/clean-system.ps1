name: Update Changelog

on: [push]

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Append Changelog
        run: echo "## $(date +%Y-%m-%d) - Update from commit ${{ github.sha }}" >> changelog.md
      - name: Commit
        run: |
          git config --global user.name 'GitHub Action'
          git config --global user.email 'action@github.com'
          git add changelog.md
          git commit -m "Auto update changelog"
          git push