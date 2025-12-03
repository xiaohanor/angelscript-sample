UCLASS(Abstract)
class UGravityBikeWhipCanvasWidget : UHazeUserWidget
{
	default Clipping = EWidgetClipping::ClipToBounds;

	UPROPERTY(BindWidget)
	UCanvasPanel ThrowCanvas;
};