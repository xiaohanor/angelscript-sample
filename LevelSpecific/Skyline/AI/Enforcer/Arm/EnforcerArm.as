UCLASS(Abstract)
class AEnforcerArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Claw;

	UPROPERTY(DefaultComponent)
	USceneComponent DynamicArm;

	UPROPERTY(DefaultComponent, Attach = "Claw")
	UGravityWhipTargetComponent WhipTarget;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent WhipResponse;
	
	AHazeActor Owner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		WhipTarget.Enable(this);
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		WhipTarget.Disable(this);
	}
}