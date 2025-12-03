class AMoonMarketCandyBalloonForm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Capsule;
}

class UMoonMarketBalloonPotionCapability : UMoonMarketPlayerShapeshiftCapability
{
	UMoonMarketBalloonPotionComponent BalloonComp;
	UPlayerMovementComponent MoveComp;

	FVector CurrentAngularVelocity;

	AMoonMarketCandyBalloonForm Balloon;

	const float MaxVelocity = 1000;
	const float DeaccelerationSpeed = 6000;
	float LastBounceTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UMoonMarketPlayerShapeshiftCapability::Setup();
		BalloonComp = UMoonMarketBalloonPotionComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnActivated();
		
		LastBounceTime = Time::GameTimeSeconds;
	
		Player.ApplySettings(BalloonComp.GravitySetting, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);

		Balloon = Cast<AMoonMarketCandyBalloonForm>(ShapeshiftInto(BalloonComp.BalloonFormClass));
		RemoveVisualBlocker();

		if(UMoonMarketPolymorphPotionComponent::Get(Player).bIsTransformed)
		{
			Player.Mesh.SetSkeletalMeshAsset(BalloonComp.Meshes[Player.OtherPlayer]);
		}
		else
		{
			Player.Mesh.SetSkeletalMeshAsset(BalloonComp.Meshes[Player]);
		}

		MoveComp.SetupShapeComponent(Balloon.Capsule);
		
		//Player.PlayOverrideAnimation(OnBlendingOut, BalloonComp.OverrideAnimation);
		const FVector RelativeLocation = Player.ActorCenterLocation - Player.MeshOffsetComponent.WorldLocation;
		Player.MeshOffsetComponent.SnapToRelativeTransform(FInstigator(this, n"Location"), Player.MeshOffsetComponent.AttachParent, FTransform(FQuat::Identity, RelativeLocation), EInstigatePriority::Low);
		Player.Mesh.SetRelativeLocation(FVector(0, 0, -60));

		auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
		PhysComp.ApplyProfileAsset(this, BalloonComp.PhysAnimProfile);

		Player.Mesh.SetForcedLOD(2);
		FMoonMarketBalloonCandyFormEventData Params;
		Params.Player = Player;
		UMoonMarketBalloonCandyFormEventHandler::Trigger_OnEnterBalloonForm(Player, Params);
		UMoonMarketBalloonCandyFormEventHandler::Trigger_OnEnterBalloonForm(Balloon, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMoonMarketPlayerShapeshiftCapability::OnDeactivated();

		if(UMoonMarketPolymorphPotionComponent::Get(Player).bIsTransformed)
		{
			Player.Mesh.SetSkeletalMeshAsset(BalloonComp.DefaultPlayerMeshes[Player.OtherPlayer]);
		}
		else
		{
			Player.Mesh.SetSkeletalMeshAsset(BalloonComp.DefaultPlayerMeshes[Player]);
		}
		//Player.StopOverrideAnimation(BalloonComp.OverrideAnimation.Animation);
		Balloon = nullptr;
		Player.Mesh.SetRelativeLocation(FVector::ZeroVector);
		Player.ClearSettingsByInstigator(this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		MoveComp.SetupShapeComponent(UShapeComponent::Get(Player));

		Player.MeshOffsetComponent.ClearOffset(FInstigator(this, n"Location"));
		Player.MeshOffsetComponent.ClearOffset(FInstigator(this, n"Rotation"));

		BalloonComp.StopCurrentInteraction();

		auto PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
		PhysComp.ClearProfileAsset(this);

		Player.Mesh.SetForcedLOD(0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if(MoveComp.IsOnWalkableGround())
		{
			const FVector AngularVelocity = MoveComp.Velocity.CrossProduct(FVector::UpVector);
			CurrentAngularVelocity = Math::VInterpTo(CurrentAngularVelocity, AngularVelocity, DeltaTime, 10);
		}
		else
		{
			const FVector AngularVelocity =  MoveComp.Velocity.CrossProduct(FVector::UpVector);
			CurrentAngularVelocity = Math::VInterpTo(CurrentAngularVelocity, AngularVelocity * 0.3, DeltaTime, 1);
		}

		const float RotationSpeed = (CurrentAngularVelocity.Size() / BalloonComp.Radius);
		const FQuat DeltaQuat = FQuat(CurrentAngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);

		Player.MeshOffsetComponent.SnapToRotation(FInstigator(this, n"Rotation"), DeltaQuat * Player.MeshOffsetComponent.ComponentQuat);

		if(!HasControl())
			return;

		if(MoveComp.Velocity.Size() > MaxVelocity)
			Player.AddMovementImpulse(-MoveComp.Velocity.GetSafeNormal() * DeaccelerationSpeed * DeltaTime);
		
		if(MoveComp.Velocity.Z < 0)
		{
			if(MoveComp.PreviousVelocity.Z >= 0)
				LastBounceTime = Time::GameTimeSeconds;
			
			const float TimeMultiplier = 0.7;
			const float TimeToReachFullGravity = 2;
			float GravityAccelerationAlpha = Math::Clamp(Math::Pow(TimeMultiplier * Time::GetGameTimeSince(LastBounceTime), 2) / TimeToReachFullGravity, 0, 1);
			float GravityAcceleration = GravityAccelerationAlpha * 5000;
			Player.AddMovementImpulse(FVector::DownVector * GravityAcceleration * DeltaTime);
		}

		if (MoveComp.HasAnyValidBlockingImpacts())
		{
			CrumbOnBounce();
			Player.PlayForceFeedback(BalloonComp.BounceForceFeedback, false, false, this);
			FHitResult FirstImpact = MoveComp.AllImpacts[0].ConvertToHitResult();
			FVector Right = -FirstImpact.Normal.CrossProduct(MoveComp.Velocity.VectorPlaneProject(FirstImpact.Normal)).GetSafeNormal();
			CurrentAngularVelocity += Right * MoveComp.Velocity.Size();

			FVector AdjustedNormal = FirstImpact.Normal;
			if(FirstImpact.Normal.DotProduct(FVector::UpVector) < 0.7)
				AdjustedNormal.Z = 0;

			AdjustedNormal.Normalize();

			float BounceStrength = BalloonComp.BounceStrength;
			BounceStrength *= Math::Saturate(MoveComp.Velocity.Size() / 500);
			BounceStrength = Math::Max(BounceStrength, 450);

			Player.AddMovementImpulse(AdjustedNormal * BounceStrength);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnBounce()
	{
		FMoonMarketBalloonCandyFormEventData Params;
		Params.Player = Player;
		UMoonMarketBalloonCandyFormEventHandler::Trigger_OnBounce(Player, Params);		
		UMoonMarketBalloonCandyFormEventHandler::Trigger_OnBounce(Balloon, Params);
	}
};