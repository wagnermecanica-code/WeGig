#!/usr/bin/env python3
"""
Converte arquivos Markdown (TERMS_OF_SERVICE.md e PRIVACY_POLICY.md) 
para HTML formatado para o site WeGig
"""

import re
from pathlib import Path

def markdown_to_html(md_content, title):
    """Converte Markdown simplificado para HTML"""
    html = md_content
    
    # Headers
    html = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html, flags=re.MULTILINE)
    html = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html, flags=re.MULTILINE)
    html = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html, flags=re.MULTILINE)
    html = re.sub(r'^#### (.+)$', r'<h4>\1</h4>', html, flags=re.MULTILINE)
    
    # Bold
    html = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html)
    
    # Links
    html = re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2">\1</a>', html)
    
    # Lists (simplificado)
    html = re.sub(r'^- (.+)$', r'<li>\1</li>', html, flags=re.MULTILINE)
    html = re.sub(r'^(\d+)\. (.+)$', r'<li>\2</li>', html, flags=re.MULTILINE)
    
    # Wrap consecutive <li> tags in <ul>
    html = re.sub(r'(<li>.*?</li>\n)+', lambda m: '<ul>\n' + m.group(0) + '</ul>\n', html, flags=re.DOTALL)
    
    # Emojis checkmarks
    html = html.replace('✅', '<span class="emoji">✅</span>')
    html = html.replace('❌', '<span class="emoji">❌</span>')
    html = html.replace('⚠️', '<span class="emoji">⚠️</span>')
    html = html.replace('🔒', '<span class="emoji">🔒</span>')
    html = html.replace('📧', '<span class="emoji">📧</span>')
    html = html.replace('🕒', '<span class="emoji">🕒</span>')
    
    # Code blocks
    html = re.sub(r'```(\w+)?\n(.+?)\n```', r'<pre><code>\2</code></pre>', html, flags=re.DOTALL)
    
    # Inline code
    html = re.sub(r'`(.+?)`', r'<code>\1</code>', html)
    
    # Paragraphs (text between blank lines)
    lines = html.split('\n')
    result = []
    in_paragraph = False
    
    for line in lines:
        stripped = line.strip()
        
        # Skip if already HTML tag
        if stripped.startswith('<'):
            if in_paragraph:
                result.append('</p>')
                in_paragraph = False
            result.append(line)
        elif stripped == '':
            if in_paragraph:
                result.append('</p>')
                in_paragraph = False
            result.append('')
        else:
            if not in_paragraph:
                result.append('<p>')
                in_paragraph = True
            result.append(line)
    
    if in_paragraph:
        result.append('</p>')
    
    return '\n'.join(result)

def create_html_page(content, title, filename):
    """Cria página HTML completa com header e footer"""
    template = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="{title} - WeGig">
    <title>{title} - WeGig</title>
    <link rel="stylesheet" href="style.css">
    <link rel="icon" type="image/png" href="favicon.png">
</head>
<body>
    <header>
        <div class="container">
            <div class="logo">
                <h1>WeGig</h1>
                <p class="tagline">Conectando Músicos</p>
            </div>
            <nav>
                <a href="index.html">Home</a>
                <a href="termos.html">Termos de Uso</a>
                <a href="privacidade.html">Privacidade</a>
            </nav>
        </div>
    </header>

    <main class="legal-page">
        <a href="index.html" class="back-button">← Voltar para Home</a>
        {content}
    </main>

    <footer>
        <div class="container">
            <div class="footer-content">
                <div class="footer-section">
                    <h4>WeGig</h4>
                    <p>Conectando músicos e bandas através da tecnologia</p>
                    <p class="copyright">&copy; 2025 WeGig. Todos os direitos reservados.</p>
                </div>
                
                <div class="footer-section">
                    <h4>Links</h4>
                    <ul>
                        <li><a href="index.html">Home</a></li>
                        <li><a href="index.html#sobre">Sobre</a></li>
                        <li><a href="index.html#funcionalidades">Funcionalidades</a></li>
                    </ul>
                </div>
                
                <div class="footer-section">
                    <h4>Legal</h4>
                    <ul>
                        <li><a href="termos.html">Termos de Uso</a></li>
                        <li><a href="privacidade.html">Política de Privacidade</a></li>
                    </ul>
                </div>
                
                <div class="footer-section">
                    <h4>Contato</h4>
                    <ul>
                        <li>Email: <a href="mailto:suporte@wegig.com.br">suporte@wegig.com.br</a></li>
                        <li>Privacidade: <a href="mailto:privacidade@wegig.com.br">privacidade@wegig.com.br</a></li>
                    </ul>
                </div>
            </div>
            
            <div class="footer-bottom">
                <p>Desenvolvido por Wagner Oliveira | Última atualização: 27 de novembro de 2025</p>
            </div>
        </div>
    </footer>
</body>
</html>
"""
    return template

def main():
    """Converte Markdown para HTML"""
    base_path = Path(__file__).parent.parent
    docs_path = base_path / 'docs'
    
    # Convert TERMS_OF_SERVICE.md
    terms_md = (base_path / 'TERMS_OF_SERVICE.md').read_text(encoding='utf-8')
    terms_html = markdown_to_html(terms_md, 'Termos de Uso')
    terms_page = create_html_page(terms_html, 'Termos de Uso', 'termos.html')
    (docs_path / 'termos.html').write_text(terms_page, encoding='utf-8')
    print('✅ termos.html criado')
    
    # Convert PRIVACY_POLICY.md
    privacy_md = (base_path / 'PRIVACY_POLICY.md').read_text(encoding='utf-8')
    privacy_html = markdown_to_html(privacy_md, 'Política de Privacidade')
    privacy_page = create_html_page(privacy_html, 'Política de Privacidade', 'privacidade.html')
    (docs_path / 'privacidade.html').write_text(privacy_page, encoding='utf-8')
    print('✅ privacidade.html criado')
    
    print('\n✨ Conversão concluída! Arquivos HTML gerados em docs/')

if __name__ == '__main__':
    main()
