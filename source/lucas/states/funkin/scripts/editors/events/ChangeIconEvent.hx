package lucas.states.funkin.scripts.events;

// ============================================
// FNF': PICO ENGINE - CHANGE ICON (SOURCE)
// Arquivo: source/events/ChangeIconEvent.hx
// Psych Engine 1.0.4 - Código Fonte Direto
// ============================================

import flixel.FlxG;
import objects.HealthIcon;
import states.PlayState;

class ChangeIconEvent
{
    // ============================================
    // REGISTRAR O EVENTO
    // Chame isso dentro de PlayState.hx no método
    // "eventPushed" ou "triggerEvent"
    // ============================================

    public static function triggerEvent(value1:String, value2:String):Void
    {
        var iconName:String = (value1 != null && value1 != '') ? value1 : 'face';
        var target:String   = (value2 != null && value2 != '') ? value2.toLowerCase() : 'player';

        switch (target)
        {
            case 'bf':
                changePlayerIcon(iconName);

            case 'dad':
                changeOpponentIcon(iconName);

            case 'both':
                changePlayerIcon(iconName);
                changeOpponentIcon(iconName);

            default:
                trace('[ChangeIconEvent] AVISO: alvo inválido "$target". Use bf, dad ou both.');
        }
    }

    // ============================================
    // TROCA O ÍCONE DO PLAYER (Pico / Boyfriend)
    // ============================================
    public static function changePlayerIcon(iconName:String):Void
    {
        var game = PlayState.instance;
        if (game == null) return;

        game.iconP1.changeIcon(iconName);
        trace('[ChangeIconEvent] Player icon → $iconName');
    }

    // ============================================
    // TROCA O ÍCONE DO OPONENTE (Dad / Enemy)
    // ============================================
    public static function changeOpponentIcon(iconName:String):Void
    {
        var game = PlayState.instance;
        if (game == null) return;

        game.iconP2.changeIcon(iconName);
        trace('[ChangeIconEvent] Opponent icon → $iconName');
    }
}


// ============================================
// COMO INTEGRAR NO PlayState.hx
// ============================================
// Encontre a função triggerEvent no PlayState.hx
// e adicione o case 'Change Icon' assim:
//
//  public function triggerEvent(name:String, value1:String, value2:String, ?strumTime:Float = 0):Void
//  {
//      switch(name)
//      {
//          case 'Change Icon':
//              ChangeIconEvent.triggerEvent(value1, value2);
//
//          // ... outros eventos já existentes ...
//      }
//  }
// ============================================


// ============================================
// COMO INTEGRAR NO eventPushed (pré-carrega)
// ============================================
// Encontre a função eventPushed no PlayState.hx
// e adicione:
//
//  function eventPushed(event:EventNote):Void
//  {
//      switch(event.event)
//      {
//          case 'Change Icon':
//              Paths.image('icons/icon-' + event.value1); // pré-carrega
//
//          // ... outros eventos ...
//      }
//  }
// ============================================


// ============================================
// COMO CHAMAR EM QUALQUER LUGAR DO SOURCE
// ============================================
// Importe no topo do arquivo:
//   import events.ChangeIconEvent;
//
// Depois chame onde quiser:
//
//   // Trocar ícone do player para pico-angry
//   ChangeIconEvent.triggerEvent('pico-angry', 'bf');
//
//   // Trocar ícone do oponente
//   ChangeIconEvent.triggerEvent('tankman', 'dad');
//
//   // Trocar os dois ao mesmo tempo
//   ChangeIconEvent.triggerEvent('pico', 'both');
//
//   // Ou disparar via evento do charter:
//   triggerEvent('Change Icon', 'pico-angry', 'bf');
// ============================================
