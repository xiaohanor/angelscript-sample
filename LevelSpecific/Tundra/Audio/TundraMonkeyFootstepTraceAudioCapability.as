class UTundraMonkeyFootstepTraceAudioCapability : UHazePlayerCapability
{
	default DebugCategory = n"Audio";
	default TickGroup = EHazeTickGroup::Audio;	

	UTundraPlayerSnowMonkeyComponent MonkeyComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftComp;
	UPlayerMovementAudioComponent PlayerAudioMoveComp;
	UTundraMonkeyMovementAudioComponent MonkeyAudioMoveComp;
	UFootstepTraceComponent TraceComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		PlayerAudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
		MonkeyAudioMoveComp = UTundraMonkeyMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsMonkey())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IsMonkey())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(MonkeyAudioMoveComp.FootTraceSettings != nullptr)
			Player.ApplySettings(MonkeyAudioMoveComp.FootTraceSettings, this);

		PlayerAudioMoveComp.RequestBlockDefaultPlayerMovement(this);
		MonkeyAudioMoveComp.bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsDebugActive())
		{
			const FVector LeftFootLoc = MonkeyComp.SnowMonkeyActor.Mesh.GetSocketLocation(MovementAudio::TundraMonkey::LeftFootSocketName);
			const FRotator LeftFootRot = MonkeyComp.SnowMonkeyActor.Mesh.GetSocketRotation(MovementAudio::TundraMonkey::LeftFootSocketName);

			const FVector LeftFootTraceEnd = LeftFootLoc + (LeftFootRot.ForwardVector * MonkeyAudioMoveComp.FootTraceSettings.LeftFoot.MinLength);

			const FVector RightFootLoc = MonkeyComp.SnowMonkeyActor.Mesh.GetSocketLocation(MovementAudio::TundraMonkey::RightFootSocketName);
			const FRotator RightFootRot = MonkeyComp.SnowMonkeyActor.Mesh.GetSocketRotation(MovementAudio::TundraMonkey::RightFootSocketName);

			const FVector RightFootTraceEnd = RightFootLoc + (RightFootRot.ForwardVector * MonkeyAudioMoveComp.FootTraceSettings.RightFoot.MinLength);

			Debug::DrawDebugCylinder(LeftFootLoc, LeftFootTraceEnd, MonkeyAudioMoveComp.FootTraceSettings.LeftFoot.SphereTraceRadius, 12, FLinearColor::Red);
			Debug::DrawDebugCylinder(RightFootLoc, RightFootTraceEnd, MonkeyAudioMoveComp.FootTraceSettings.RightFoot.SphereTraceRadius, 12, FLinearColor::Red);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsOfClass(UAudioPlayerFootTraceSettings, this);
		
		PlayerAudioMoveComp.UnRequestBlockDefaultPlayerMovement(this);
		MonkeyAudioMoveComp.bIsActive = false;
	}
	
	private bool IsMonkey() const
	{
		return ShapeshiftComp.CurrentShapeType == ETundraShapeshiftShape::Big;
	}
}