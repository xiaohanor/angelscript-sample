UCLASS(Abstract)
class APrisonDronesBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this,n"OnPlayerImpact");
	}

	UFUNCTION()
	private void OnPlayerImpact(AHazePlayerCharacter Player)
	{
		FVector Force = GetActorLocation() - Player.GetActorLocation(); 
		Force.Normalize();
		Force *= 1000;

		TranslateComp.ApplyImpulse(Player.GetActorLocation(), Force);
		AxisRotateComp.ApplyImpulse(Player.GetActorLocation(), Force*1000);
	}
};
