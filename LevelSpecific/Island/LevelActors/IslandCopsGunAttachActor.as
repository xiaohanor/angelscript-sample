UCLASS(Abstract)
class AIslandCopsGunAttachActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)	
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent)	
	UScifiCopsGunThrowTargetableComponent CopsGunThrowTargetableComponent;
	UPROPERTY(DefaultComponent)
	UScifiCopsGunImpactResponseComponent ImpactResponseComponent;
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
}
