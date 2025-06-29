return {
  'Shopify/shadowenv.vim',
  cond = function()
    return vim.fn.executable 'shadowenv' == 1
  end,
}
