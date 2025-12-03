class USummitAdultDragonCircleStrafeManagerCirclingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	const float CameraSplinePosFollowDuration = 2.5;

	ASummitAdultDragonCircleStrafeManager StrafeManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeManager = Cast<ASummitAdultDragonCircleStrafeManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::Circling)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Player : Game::Players)
		{
			auto StrafeComp = UAdultDragonCircleStrafeComponent::Get(Player);
			StrafeComp.StrafeManager = StrafeManager;
		}

		Game::GetZoe().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast, EHazeViewPointPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::GetZoe().ClearViewSizeOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MoveAmount = StrafeManager.CameraRotationSpeed * DeltaTime;
		if(StrafeManager.bStrafingIsFlipped)
			MoveAmount *= -1;

		StrafeManager.AddActorLocalRotation(FRotator(0, -MoveAmount, 0).Quaternion());
		
		// auto CameraUserComp = UCameraUserComponent::Get(Game::Zoe);
		// CameraUserComp.AddDesiredRotation(FRotator(0, 100 * DeltaTime, 0), this);
		// StrafeManager.Boss.CirclingCamera.AddLocalRotation(FRotator(0, 500 * DeltaTime, 0));


		// auto SpringArmCamera = StrafeManager.Boss.CirclingCamera;
		// SpringArmCamera.AddLocalRotation(FRotator(0, 500 * DeltaTime, 0));
		// StrafeManager.CurrentSplinePos.Move(MoveAmount);
		// AccSplineFollowPos.AccelerateTo(StrafeManager.CurrentSplinePos.WorldLocation, CameraSplinePosFollowDuration, DeltaTime);
		// StrafeManager.ActorLocation = AccSplineFollowPos.Value;
		// TEMPORAL_LOG(StrafeManager)
		// 	.Sphere("Circle Strafe: Accelerated Spline Follow Pos", AccSplineFollowPos.Value, 200, FLinearColor::LucBlue, 50)
		// 	.Sphere("Circle Strafe: Spline Follow Pos", StrafeManager.CurrentSplinePos.WorldLocation, 200, FLinearColor::DPink, 50)
		// ;

		// AActor Boss = StrafeManager.Boss;
		// FVector DirToBoss = (Boss.ActorLocation - StrafeManager.ActorLocation).GetSafeNormal();
		// FRotator FacingBoss = FRotator::MakeFromX(DirToBoss);
		// StrafeManager.SetActorRotation(FacingBoss);
	}
};