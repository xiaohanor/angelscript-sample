class UFantasyOtterFootstepAudioTraceCapability : UHazePlayerCapability
{
	default DebugCategory = n"Audio";
	default TickGroup = EHazeTickGroup::Audio;

	UFantasyOtterFootstepTraceAudioComponent TraceComp;
	UHazeMovementComponent MoveComp;
	UPlayerMovementAudioComponent PlayerMoveAudioComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftComp;	
	UPlayerSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TraceComp = UFantasyOtterFootstepTraceAudioComponent::Get(Player);	
		SwimComp = UPlayerSwimmingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsOtter())
			return false;

		if(SwimComp.IsSwimming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SwimComp.IsSwimming())
			return true;

		if(!IsOtter())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(TraceComp.Settings != nullptr)
			Player.ApplySettings(TraceComp.Settings, this);

		PlayerMoveAudioComp.RequestBlockDefaultPlayerMovement(this);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		PlayerMoveAudioComp.UnRequestBlockDefaultPlayerMovement(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsDebugActive())
		{
			auto OtterMesh = ShapeshiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Small);

			const FVector LeftFootLoc = OtterMesh.GetSocketLocation(MovementAudio::TundraMonkey::LeftFootSocketName);
			const FRotator LeftFootRot = OtterMesh.GetSocketRotation(MovementAudio::TundraMonkey::LeftFootSocketName);

			const FVector LeftFootTraceEnd = LeftFootLoc + (LeftFootRot.ForwardVector * TraceComp.Settings.LeftFoot.MinLength);

			const FVector RightFootLoc = OtterMesh.GetSocketLocation(MovementAudio::TundraMonkey::RightFootSocketName);
			const FRotator RightFootRot = OtterMesh.GetSocketRotation(MovementAudio::TundraMonkey::RightFootSocketName);

			const FVector RightFootTraceEnd = RightFootLoc + (RightFootRot.ForwardVector * TraceComp.Settings.RightFoot.MinLength);

			Debug::DrawDebugCylinder(LeftFootLoc, LeftFootTraceEnd, TraceComp.Settings.LeftFoot.SphereTraceRadius, 12, FLinearColor::Red);
			Debug::DrawDebugCylinder(RightFootLoc, RightFootTraceEnd, TraceComp.Settings.RightFoot.SphereTraceRadius, 12, FLinearColor::Red);
		}
	}

	private bool IsOtter() const
	{
		return ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Small;
	}
}