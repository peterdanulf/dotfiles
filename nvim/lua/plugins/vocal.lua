return {
  "kyza0d/vocal.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("vocal").setup({
      recording_dir = os.getenv("HOME") .. "/recordings",
      delete_recordings = true,
      keymap = "<leader>v",
      local_model = {
        model = "base",
        path = os.getenv("HOME") .. "/whisper",
      },
      api = {
        model = "whisper-1",
        temperature = 0,
        timeout = 30,
      },
    })
    
    -- Override insert function to always yank instead
    vim.defer_fn(function()
      local ok, buffer_mod = pcall(require, "vocal.buffer")
      if ok and buffer_mod then
        buffer_mod.insert_at_cursor = function(text)
          vim.fn.setreg('"', text)
          vim.fn.setreg("+", text)
          print("Transcription copied to clipboard: " .. (text:len() > 50 and text:sub(1, 50) .. "..." or text))
        end
      end
    end, 100)
  end,
}
