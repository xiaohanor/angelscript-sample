class UVillageCanalExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UVillageCanalExitPlayerComponent ExitComp;

	float SplineDist = 0.0;
	bool bReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExitComp = UVillageCanalExitPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ExitComp.FollowSpline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ExitComp.FollowSpline == nullptr)
			return true;

		if (bReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ResetMovement();
		Player.SetActorVelocity(FVector(0.0, 0.0, -2500.0));
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		ExitComp.FollowSpline = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(n"AirMovement", this);

		SplineDist += 2500.0 * DeltaTime;

		FVector Loc = Math::VInterpConstantTo(Player.ActorLocation, ExitComp.FollowSpline.Spline.GetWorldLocationAtSplineDistance(SplineDist), DeltaTime, 2500.0);
		Player.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpTo(Player.ActorRotation, ExitComp.FollowSpline.ActorRotation, DeltaTime, 2.0);
		Player.SetActorRotation(Rot);

		if (Player.ActorLocation.Equals(ExitComp.FollowSpline.Spline.GetWorldLocationAtSplineFraction(1.0), 50.0))
			bReachedEnd = true;
	}
};

class UVillageCanalExitPlayerComponent : UActorComponent
{
	ASplineActor FollowSpline;
	AActor SuckedIntoPipeTarget;

	UFUNCTION()
	void TriggerExit(ASplineActor Spline)
	{
		FollowSpline = Spline;
	}

	
	UFUNCTION()
	void TriggerSuckedIntoPipe(AActor TargetActor)
	{
		SuckedIntoPipeTarget = TargetActor;
	}
};

class AVillageCanalExitActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UFUNCTION()
	void TriggerExit(AHazePlayerCharacter Player, ASplineActor Spline)
	{
		UVillageCanalExitPlayerComponent Comp = UVillageCanalExitPlayerComponent::Get(Player);
		Comp.TriggerExit(Spline);
	}

	UFUNCTION()
	void TriggerSuckedIntoPipe(AHazePlayerCharacter Player, AActor TargetActor)
	{
		UVillageCanalExitPlayerComponent Comp = UVillageCanalExitPlayerComponent::Get(Player);
		Comp.TriggerSuckedIntoPipe(TargetActor);
	}
}