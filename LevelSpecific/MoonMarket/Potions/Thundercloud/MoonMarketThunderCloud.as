UCLASS(Abstract)
class AMoonMarketThunderCloud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Cloud;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Rain;

	UPROPERTY(DefaultComponent)
	UDecalComponent ShadowDecal;
	default ShadowDecal.bAbsoluteLocation = true;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Capsule;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphShapeComponent ShapeComp;
	default ShapeComp.ShapeData.ShapeTag = "ThunderCloud";
	default ShapeComp.ShapeData.bIsBubbleBlockingShape = true;
	default ShapeComp.ShapeData.bCanDash = false;
	default ShapeComp.ShapeData.bUseCustomMovement = true;
	default ShapeComp.ShapeData.bCancelByThunder = false;
};