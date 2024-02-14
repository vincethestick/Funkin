package funkin.graphics.adobeanimate;

import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;
import flixel.math.FlxPoint;

/**
 * A sprite which provides convenience functions for rendering a texture atlas with animations.
 */
class FlxAtlasSprite extends FlxAnimate
{
  static final SETTINGS:Settings =
    {
      // ?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: #if debug false #else false #end,
      Antialiasing: true,
      ScrollFactor: null,
      // Offset: new FlxPoint(0, 0), // This is just FlxSprite.offset
    };

  /**
   * Signal dispatched when an animation finishes playing.
   */
  public var onAnimationFinish:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  var currentAnimation:String;

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, path:String, ?settings:Settings)
  {
    if (settings == null) settings = SETTINGS;

    super(x, y, path, settings);

    if (this.anim.curInstance == null)
    {
      throw 'FlxAtlasSprite not initialized properly. Are you sure the path (${path}) exists?';
    }

    onAnimationFinish.add(cleanupAnimation);

    // This defaults the sprite to play the first animation in the atlas,
    // then pauses it. This ensures symbols are intialized properly.
    this.anim.play('');
    this.anim.pause();
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    return this.anim.getFrameLabels();
    // return [""];
  }

  /**
   * @param id A string ID of the animation.
   * @return Whether the animation was found on this sprite.
   */
  public function hasAnimation(id:String):Bool
  {
    return getLabelIndex(id) != -1;
  }

  /**
   * @return The current animation being played.
   */
  public function getCurrentAnimation():String
  {
    return this.currentAnimation;
  }

  /**
   * Plays an animation.
   * @param id A string ID of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
   */
  public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, ?loop:Bool = false):Void
  {
    if (loop == null) loop = false;

    // Skip if not allowed to play animations.
    if ((!canPlayOtherAnims && !ignoreOther)) return;

    if (id == null || id == '') id = this.currentAnimation;

    if (this.currentAnimation == id && !restart)
    {
      if (anim.isPlaying)
      {
        // Skip if animation is already playing.
        return;
      }
      else
      {
        // Resume animation if it's paused.
        anim.play('', false, false);
      }
    }

    // Skip if the animation doesn't exist
    if (!hasAnimation(id))
    {
      trace('Animation ' + id + ' not found');
      return;
    }

    anim.callback = function(_, frame:Int) {
      if (frame == (anim.getFrameLabel(id).duration - 1) + anim.getFrameLabel(id).index)
      {
        if (loop) playAnimation(id, true, false, true);
        else
          onAnimationFinish.dispatch(id);
      }
    };

    // Prevent other animations from playing if `ignoreOther` is true.
    if (ignoreOther) canPlayOtherAnims = false;

    // Move to the first frame of the animation.
    goToFrameLabel(id);
    this.currentAnimation = id;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  /**
   * Stops the current animation.
   */
  public function stopAnimation():Void
  {
    if (this.currentAnimation == null) return;

    this.anim.removeAllCallbacksFrom(getNextFrameLabel(this.currentAnimation));

    goToFrameIndex(0);
  }

  function addFrameCallback(label:String, callback:Void->Void):Void
  {
    var frameLabel = this.anim.getFrameLabel(label);
    frameLabel.add(callback);
  }

  inline function goToFrameLabel(label:String):Void
  {
    this.anim.goToFrameLabel(label);
  }

  inline function getNextFrameLabel(label:String):String
  {
    return listAnimations()[(getLabelIndex(label) + 1) % listAnimations().length];
  }

  inline function getLabelIndex(label:String):Int
  {
    return listAnimations().indexOf(label);
  }

  inline function goToFrameIndex(index:Int):Void
  {
    this.anim.curFrame = index;
  }

  public function cleanupAnimation(_:String):Void
  {
    canPlayOtherAnims = true;
    this.currentAnimation = null;
    this.anim.stop();
  }
}
