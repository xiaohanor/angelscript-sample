UCLASS(Abstract)
class ATundraSidePunchableTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchInteractComp;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem PunchVFX;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FinalPunchVFX;

	UPROPERTY(EditAnywhere)
	float Angle = 90.0;

	TOptional<FQuat> TargetQuat;
	FHazeAcceleratedQuat AcceleratedQuat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PunchInteractComp.OnPunch.AddUFunction(this, n"OnPunch");
		PunchInteractComp.OnCompletedPunch.AddUFunction(this, n"OnCompletePunch");
	}
	
	UFUNCTION()
	private void OnPunch(FVector PlayerLocation)
	{
		FVector Location = UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().GetSocketLocation(n"RightAttach");
		Mesh.GetClosestPointOnCollision(Location, Location);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PunchVFX, Location);
	}

	UFUNCTION()
	private void OnCompletePunch(FVector PlayerLocation)
	{
		FQuat DeltaQuat = Math::RotatorFromAxisAndAngle(PunchInteractComp.RightVector, Angle).Quaternion();
		TargetQuat.Set(DeltaQuat * Mesh.ComponentQuat);
		AcceleratedQuat.SnapTo(Mesh.ComponentQuat);

		FVector Location = UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().GetSocketLocation(n"RightAttach");
		Mesh.GetClosestPointOnCollision(Location, Location);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(FinalPunchVFX, Location);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!TargetQuat.IsSet())
			return;

		Mesh.ComponentQuat = AcceleratedQuat.ThrustTo(TargetQuat.Value, 20.0, DeltaTime);
	}
}