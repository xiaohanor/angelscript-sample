
class UTundraTreeGuardianFootstepTraceAudioCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Audio;
    default DebugCategory = n"Audio";
	
	FFootstepTrace LeftFootTrace;
	FFootstepTrace RightFootTrace;

	UPlayerFootstepTraceComponent TraceComp;
	UPlayerMovementAudioComponent PlayerMoveAudioComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftComp;

	TMap<EFootType, FVector> TrackedFootLocations;
	UHazeMovementComponent MoveComp;

	USkeletalMeshComponent TreeMesh;

	FVector CachedPlayerLocation;	

	AHazeActor TreeGuardian;

	float FootstepsCooldownMultiplier = 1.0; // Used to reduce cooldown time on activation, to avoid missing footsteps after transform
	const float SLOPE_TILT_MAX_ANGLE = 45.0;

	UPROPERTY(EditDefaultsOnly)
	UAudioPlayerFootTraceSettings FootTraceSettings = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
		TraceComp = UPlayerFootstepTraceComponent::Get(Player);	

		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);	
		LeftFootTraceData.Foot = EFootType::Left;
		LeftFootTraceData.Trace = LeftFootTrace;

		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);
		RightFootTraceData.Foot = EFootType::Right;
		RightFootTraceData.Trace = RightFootTrace;

		TreeMesh = ShapeshiftComp.GetMeshForShapeType(ETundraShapeshiftShape::Big);
		TreeGuardian = Cast<AHazeActor>(TreeMesh.GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsInTreeForm())
			return false;

		if(!MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(IsInTreeForm())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(FootTraceSettings != nullptr)
			Player.ApplySettings(FootTraceSettings, this);

		PlayerMoveAudioComp.RequestBlockDefaultPlayerMovement(this);

		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		InitializeFootData(LeftFootTraceData);

		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);
		InitializeFootData(RightFootTraceData);	

		FootstepsCooldownMultiplier = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerMoveAudioComp.UnRequestBlockDefaultPlayerMovement(this);
		Player.ClearSettingsOfClass(UAudioPlayerFootTraceSettings, this);
	}

	FVector GetTraceFrameStartPos(const FPlayerFootstepTraceData& InTraceData)
	{
		return TreeMesh.GetSocketLocation(InTraceData.Settings.SocketName);
	}

	FVector GetTraceFrameEndPos(const FPlayerFootstepTraceData& InTraceData, const float InTraceLength)
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = TreeMesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}

	float GetScaledTraceLength(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		const float NormalizedSpeed = MoveComp.GetVelocity().Size() / InFootstepTraceData.Settings.MaxVelo;
		const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	bool ValidateFootFrameVelo(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		FVector CachedLocation;
		if(!TrackedFootLocations.Find(InFootstepTraceData.Foot, CachedLocation))
			return false;

		const float VerticalDelta = InFootstepTraceData.Start.Z - CachedLocation.Z;

		const FVector PlayerVelo = Player.GetActorLocation() - CachedPlayerLocation;
		InFootstepTraceData.Velo = (InFootstepTraceData.Start - CachedLocation) - PlayerVelo;

		// Has the foot moved enough?
		if(Math::IsNearlyZero(VerticalDelta, InFootstepTraceData.Settings.MinRequiredVelo))
			return false;
		
		// Has the foot to much upwards velocity to invalidate a new footstep?
		float WorldUpDot = TraceComp.MoveComp.WorldUp.GetSafeNormal().DotProduct(InFootstepTraceData.Velo.GetSafeNormal());

		if(WorldUpDot > 0.5)		
		{
			if(!InFootstepTraceData.Trace.bGrounded)
				InFootstepTraceData.Trace.bPerformed = true;
		}

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FPlayerFootstepTraceData& LeftFootTraceData = TraceComp.GetTraceData(EFootType::Left);
		FPlayerFootstepTraceData& RightFootTraceData = TraceComp.GetTraceData(EFootType::Right);

		EvaluateFootstepTraceData(LeftFootTraceData);
		EvaluateFootstepTraceData(RightFootTraceData);	

		TrackedFootLocations.FindOrAdd(EFootType::Left) = LeftFootTraceData.Start;
		TrackedFootLocations.FindOrAdd(EFootType::Right) = RightFootTraceData.Start;

		CachedPlayerLocation = Player.GetActorLocation();

		FootstepsCooldownMultiplier = Math::FInterpConstantTo(FootstepsCooldownMultiplier, 1.0, DeltaTime, 0.5);
	}

	void EvaluateFootstepTraceData(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		if(EvaluateTrace(InFootstepTraceData))	
		{	
			if(!CanPerformFootstep(InFootstepTraceData))
				return;

			const bool bIsPlant = InFootstepTraceData.Trace.bGrounded;
			FTundraPlayerTreeGuardianAudioFootstepParams FootstepParams;	

			UPhysicalMaterial PhysMat = nullptr;
			if(bIsPlant)
			{
				FHazeTraceSettings TraceSettings = TraceComp.InitTraceSettings();
				PhysMat = AudioTrace::GetPhysMaterialFromHit(InFootstepTraceData.Hit, TraceSettings);	
				InFootstepTraceData.LastPhysMat = PhysMat;

				// Slope tilt
				const float SlopeTiltDegrees = InFootstepTraceData.Hit.ImpactNormal.GetAngleDegreesTo(MoveComp.WorldUp);
				FootstepParams.SlopeTilt = Math::GetMappedRangeValueClamped(FVector2D(-SLOPE_TILT_MAX_ANGLE, SLOPE_TILT_MAX_ANGLE), FVector2D(-1.0, 1.0), SlopeTiltDegrees);
			}
			else
			{
				PhysMat = InFootstepTraceData.LastPhysMat;
				if(PhysMat == nullptr)
					return;
			}
			
			FootstepParams.AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
		
			if(IsDebugActive())
			{
				FString AudioName = FootstepParams.AudioPhysMat != nullptr ? FootstepParams.AudioPhysMat.GetName().ToString() : "None";
				FString PhysName = PhysMat != nullptr ? PhysMat.GetName().ToString() : "None"; 

				// PrintToScreen("OnFootstepTrace_Right, Audio: " + AudioName);
				// PrintToScreen("OnFootstepTrace_Right, Phys: " + PhysName);
			}
			
			if(bIsPlant)
			{
				if(InFootstepTraceData.Foot == EFootType::Left)
					UTreeGuardianBaseEffectEventHandler::Trigger_OnFootstepAudio_Plant_Left(TreeGuardian, FootstepParams);	
				else
					UTreeGuardianBaseEffectEventHandler::Trigger_OnFootstepAudio_Plant_Right(TreeGuardian, FootstepParams);	

			}
			else
				UTreeGuardianBaseEffectEventHandler::Trigger_OnFootstepAudio_Release(TreeGuardian, FootstepParams);

			QueryCooldowns(InFootstepTraceData);
		}	
	}

	bool EvaluateTrace(FPlayerFootstepTraceData& InFootstepTraceData)
	{
		// Reset performed-flag
		InFootstepTraceData.Trace.bPerformed = false;

		// Get trace bounds from foot
		InFootstepTraceData.Start = GetTraceFrameStartPos(InFootstepTraceData);

		// // If foot hasn't moved, or moved in opposite direction of ground, bail
		// if(!ValidateFootFrameVelo(InFootstepTraceData))
		// 	return false;

		// Get Foot Trace Length	
		const float TraceLength = GetScaledTraceLength(InFootstepTraceData);

		InFootstepTraceData.End = GetTraceFrameEndPos(InFootstepTraceData, TraceLength);

		//Debug::DrawDebugLine(InFootstepTraceData.Start, InFootstepTraceData.End, FLinearColor::Red);
		
		return TraceComp.PerformFootTrace_Sphere(InFootstepTraceData, InFootstepTraceData.Settings.SphereTraceRadius, bDebug = IsDebugActive());		
	}	

	private bool CanPerformFootstep(FPlayerFootstepTraceData& TraceData)
	{
		const float TriggerTimeStamp = TraceData.Trace.bGrounded ? TraceData.PlantTriggerTimeStamp : TraceData.ReleaseTriggerTimeStamp;
		return Time::GetRealTimeSince(TriggerTimeStamp) >= (TraceData.Settings.TriggerCooldown * FootstepsCooldownMultiplier);		
	}

	private void QueryCooldowns(FPlayerFootstepTraceData& TraceData)
	{
		if(TraceData.Trace.bGrounded)
		{
			TraceData.PlantTriggerTimeStamp = Time::GetRealTimeSeconds();		
		}
		else
		{
			TraceData.ReleaseTriggerTimeStamp = Time::GetRealTimeSeconds();		
		}
	}

	private FPlayerFootstepTraceData& GetOtherFoot(const FPlayerFootstepTraceData& InTraceData)
	{
		if(InTraceData.Foot == EFootType::Left)
			return TraceComp.GetTraceData(EFootType::Right);
		
		return TraceComp.GetTraceData(EFootType::Right);
	}

	void InitializeFootData(FPlayerFootstepTraceData& InFootData)
	{
		InFootData.PlantTriggerTimeStamp = SMALL_NUMBER;
		InFootData.ReleaseTriggerTimeStamp = SMALL_NUMBER;

		InFootData.Trace.bGrounded = true;
		InFootData.Trace.bPerformed = false;
	}

	private bool IsInTreeForm() const
	{
		return ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Big;
	}
}