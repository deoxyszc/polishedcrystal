"""Build the Chinese UI suite through one language-selected configuration."""
def generate(source, language, font, terms):
    from suite_layout import select, asm_constants
    if select(language) is None:
        return
    (source / "data/zh/suite_layout.asm").write_text(asm_constants(language))
    import summary_assets
    import ability_assets
    import item_panel
    import summary_moves
    import orange_assets
    import pink_assets
    import hud_names
    import party_footer
    summary_assets.generate(source, font, terms, language=language)
    for module in (ability_assets, item_panel, summary_moves):
        module.generate(source, language, font)
    for module in (orange_assets, pink_assets):
        module.generate(source, language, font, terms)
    hud_names.generate(source, language, font)
    hud_names.generate(source, language, font, party=True)
    party_footer.generate(source, language, font)
