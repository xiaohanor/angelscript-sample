class AForgePipePusher : AHazeActor
{

UPROPERTY(DefaultComponent, RootComponent)
USceneComponent Root;

UPROPERTY(DefaultComponent, Attach = Root)
USceneComponent MeshRoot;

UPROPERTY(EditAnywhere)
UBoxComponent ImpactBox;

UPROPERTY(EditAnywhere)
ASplineActor SplineObject;

UHazeSplineComponent SplineComp;

UTeenDragonTailAttackResponseComponent TailAttack;

UPROPERTY(EditAnywhere)
AAcidFireSprayContraption FirePipe;

float CurrentDistance;

float MoveSpeed = 200.0;

UFUNCTION(BlueprintOverride)
void BeginPlay()
{
	SplineComp = SplineObject.Spline;

	ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(CurrentDistance);

	TailAttack.OnHitByRoll.AddUFunction(this, n"HitByRoll");
}



	UFUNCTION()
	private void HitByRoll(FRollParams Params)
	{
		CurrentDistance += MoveSpeed;
	}
}