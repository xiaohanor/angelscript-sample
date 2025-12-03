UCLASS(Abstract, ComponentWrapperClass)
class APinballAutoAim : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	protected UPinballAutoAimComponent AutoAimComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	private UEditorBillboardComponent Billboard;
#endif
}