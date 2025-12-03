class UPlayerWallScrambleTransitionAudioTraceCapability : UPlayerFootstepTraceCapability
{
	UPlayerWallScrambleComponent WallScrambleComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WallScrambleComp = UPlayerWallScrambleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		return WallScrambleComp.Data.State == EPlayerWallScrambleState::Scramble;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		return WallScrambleComp.Data.State != EPlayerWallScrambleState::Scramble;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if(MoveComp.PreviousHorizontalVelocity.Size() > 300)
		{
			FPlayerFootstepTraceData& TraceData = TraceComp.GetTraceData(EFootType::Left);

			FHazeTraceSettings TraceSettings = TraceComp.InitTraceSettings();
			UPhysicalMaterial PhysMat = AudioTrace::GetPhysMaterialFromHit(TraceData.Hit, TraceSettings);	
			TraceData.LastPhysMat = PhysMat;

			FPlayerFootstepParams FootstepParams;
			FootstepParams.MovementState = n"Land_BothLegs_HighInt";
			FootstepParams.AudioPhysMat = TraceComp.FoliageMaterialOverride != nullptr ? TraceComp.FoliageMaterialOverride : Cast<UPhysicalMaterialAudioAsset>(PhysMat.AudioAsset);
			FootstepParams.FootStepType = TraceData.Foot;
			FootstepParams.MakeUpGain = TraceData.Settings.MakeUpGain;
			FootstepParams.Pitch = TraceData.Settings.Pitch;
			FootstepParams.SlopeTilt = GetSlopeTiltAngle();
			FootstepParams.PhysicalSurfaceType = PhysMat.SurfaceType;
			FootstepParams.ImpactPoint = TraceData.Hit.ImpactPoint;
			FootstepParams.ImpactNormal = TraceData.Hit.ImpactNormal;

			bool bIsBothFeet = false;
			EFootType FootType = TraceData.Foot;	

			if(MaterialComp.GetMaterialEvent(FootstepParams.AudioPhysMat.FootstepData.FootstepTag, FootstepParams.MovementState, FootType, FootType, FootstepParams.MaterialEvent, bIsBothFeet))
			{					
				UMovementAudioEventHandler::Trigger_OnFootstepTrace_Left(Player, FootstepParams);
				QueryCooldowns(TraceData, bIsBothFeet);
			}	
		}
	}
}