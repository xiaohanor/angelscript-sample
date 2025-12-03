UCLASS(Abstract)
class ALiftSectionShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateVerticalComp;
	
	UPROPERTY(DefaultComponent, Attach = AxisRotateVerticalComp)
	USceneComponent Body;

	UPROPERTY(DefaultComponent, Attach = Body)
	USceneComponent Left;

	UPROPERTY(DefaultComponent, Attach = Body)
	USceneComponent Right;

	UPROPERTY(DefaultComponent, Attach = Body)
	USceneComponent WingLeft;

	UPROPERTY(DefaultComponent, Attach = Body)
	USceneComponent WingRight;
}