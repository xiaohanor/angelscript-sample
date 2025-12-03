class USkylineSentryDroneTurretComponent : UBasicAIProjectileLauncherComponent
{
	TArray<AHazeActor> Targets;

	AHazeActor CurrentTarget;

	FVector InitialDirection;

	TArray<UHazeTeam> TargetTeams;

	UPROPERTY(EditAnywhere)
	USkylineSentryDroneTurretSettings Settings;

	FVector AimDirection;

//	UPROPERTY()
//	TSubclassOf<ABasicAIProjectile> ProjectileClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		auto HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.ApplyDefaultSettings(Settings);

		Settings = USkylineSentryDroneTurretSettings::GetSettings(HazeOwner);

		InitialDirection = RelativeRotation.ForwardVector;

		if (Settings.bTargetMio)
			AddTarget(Game::Mio);
		if (Settings.bTargetZoe)
			AddTarget(Game::Zoe);

		auto GravityWhipResponseComponent = UGravityWhipResponseComponent::Get(Owner);
		if (GravityWhipResponseComponent != nullptr)
		{
			GravityWhipResponseComponent.OnGrabbed.AddUFunction(this, n"OnWhipGrabbed");
			GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"OnWhipReleased");
			GravityWhipResponseComponent.OnThrown.AddUFunction(this, n"OnWhipThrown");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	AimDirection = Owner.ActorTransform.InverseTransformVectorNoScale(AimDirection);

	//	Debug::DrawDebugLine(WorldLocation, WorldLocation + Owner.ActorTransform.TransformVectorNoScale(InitialDirection) * 300.0, FLinearColor::Blue, 20.0, 0.0);
	//	Debug::DrawDebugLine(WorldLocation, WorldLocation + AimDirection * 500.0, FLinearColor::Red, 10.0, 0.0);

		if (CurrentTarget == nullptr)
			AimDirection = Owner.ActorTransform.TransformVectorNoScale(InitialDirection);

		float RotationSpeed = 0.0;
		if(Settings != nullptr)
			RotationSpeed = Settings.RotationSpeed;
		FQuat AimRotation = FQuat::Slerp(ComponentQuat, FQuat::MakeFromXZ(AimDirection, Owner.ActorUpVector), DeltaSeconds * RotationSpeed);
		SetWorldRotation(AimRotation);
	}

	UFUNCTION()
	private void OnWhipGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		if (Settings.bAIHostileWhenGrabbed)
			TargetTeams.Add(HazeTeam::GetTeam(Settings.DefaultTargetTeamName));
	}

	UFUNCTION()
	private void OnWhipReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if (Settings.bAIHostileWhenGrabbed)
			TargetTeams.Remove(HazeTeam::GetTeam(Settings.DefaultTargetTeamName));
	}

	UFUNCTION()
	private void OnWhipThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		if (Settings.bAIHostileWhenGrabbed)
			TargetTeams.Remove(HazeTeam::GetTeam(Settings.DefaultTargetTeamName));
	}

	UFUNCTION(DevFunction)
	void MakeHostileToBasicAITeam()
	{
		TargetTeams.Add(HazeTeam::GetTeam(Settings.DefaultTargetTeamName));
	}

	UFUNCTION(DevFunction)
	void AddTargetTeam(FName TeamName)
	{
		auto Team = HazeTeam::GetTeam(TeamName);

		if (Team == nullptr)
			return;

		TargetTeams.Add(Team);
	}

	UFUNCTION(DevFunction)
	void RemoveTargetTeam(FName TeamName)
	{
		auto Team = HazeTeam::GetTeam(TeamName);

		if (Team == nullptr)
			return;

		TargetTeams.Remove(Team);
	}	

	UFUNCTION()
	void AddTarget(AHazeActor Target)
	{
		Targets.Add(Target);
	}

	UFUNCTION()
	void RemoveTarget(AHazeActor Target)
	{
		Targets.Remove(Target);
	}

	UFUNCTION()
	void Fire()
	{
		FVector LaunchDirection = Math::VRandCone(ForwardVector, Math::DegreesToRadians(Settings.SpreadAngle));
		Launch(LaunchDirection * Settings.LaunchSpeed);
	}
}