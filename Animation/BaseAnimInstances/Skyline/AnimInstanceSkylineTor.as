namespace FeatureTagSkylineTor
{
	const FName HurtReaction = n"HurtReaction";
	const FName Interrupt = n"Interrupt";
	const FName WhipSlip = n"WhipSlip";
	const FName SwingAttack = n"SwingAttack";
	const FName DebrisAttack = n"DebrisAttack";
	const FName EjectAttack = n"EjectAttack";
	const FName RainDebrisAttack = n"RainDebrisAttack";
	const FName PulseAttack = n"PulseAttack";
	const FName Exposed = n"Exposed";
	const FName Disarm = n"Disarm";
	const FName HammerVolley = n"HammerVolley";
	const FName HammerSpiral = n"HammerSpiral";
	const FName DeployMine = n"DeployMine";
	const FName ControlMine = n"ControlMine";
	const FName Death = n"Death";
	const FName Whirlwind = n"Whirlwind";
	const FName ChargeAttack = n"ChargeAttack";
	const FName SmashAttack = n"SmashAttack";
	const FName ClearArea = n"ClearArea";
	const FName DiveAttack = n"DiveAttack";
	const FName StormAttack = n"StormAttack";
	const FName OpportunityAttack = n"OpportunityAttack";
	const FName BoloAttack = n"BoloAttack";
	const FName RecallHammer = n"RecallHammer";
}

struct FSkylineTorFeatureTags
{
	UPROPERTY()
	FName HurtReaction = FeatureTagSkylineTor::HurtReaction;
	UPROPERTY()
	FName Interrupt = FeatureTagSkylineTor::Interrupt;
	UPROPERTY()
	FName WhipSlip = FeatureTagSkylineTor::WhipSlip;
	UPROPERTY()
	FName SwingAttack = FeatureTagSkylineTor::SwingAttack;
	UPROPERTY()
	FName DebrisAttack = FeatureTagSkylineTor::DebrisAttack;
	UPROPERTY()
	FName EjectAttack = FeatureTagSkylineTor::EjectAttack;
	UPROPERTY()
	FName RainDebrisAttack = FeatureTagSkylineTor::RainDebrisAttack;
	UPROPERTY()
	FName PulseAttack = FeatureTagSkylineTor::PulseAttack;
	UPROPERTY()
	FName Exposed = FeatureTagSkylineTor::Exposed;
	UPROPERTY()
	FName Disarm = FeatureTagSkylineTor::Disarm;
	UPROPERTY()
	FName HammerVolley = FeatureTagSkylineTor::HammerVolley;
	UPROPERTY()
	FName HammerSpiral = FeatureTagSkylineTor::HammerSpiral;
	UPROPERTY()
	FName DeployMine = FeatureTagSkylineTor::DeployMine;
	UPROPERTY()
	FName ControlMine = FeatureTagSkylineTor::ControlMine;
	UPROPERTY()
	FName Death = FeatureTagSkylineTor::Death;
	UPROPERTY()
	FName Whirlwind = FeatureTagSkylineTor::Whirlwind;
	UPROPERTY()
	FName ChargeAttack = FeatureTagSkylineTor::ChargeAttack;
	UPROPERTY()
	FName SmashAttack = FeatureTagSkylineTor::SmashAttack;
	UPROPERTY()
	FName ClearArea = FeatureTagSkylineTor::ClearArea;
	UPROPERTY()
	FName DiveAttack = FeatureTagSkylineTor::DiveAttack;
	UPROPERTY()
	FName StormAttack = FeatureTagSkylineTor::StormAttack;
	UPROPERTY()
	FName OpportunityAttack = FeatureTagSkylineTor::OpportunityAttack;
	UPROPERTY()
	FName BoloAttack = FeatureTagSkylineTor::BoloAttack;
	UPROPERTY()
	FName RecallHammer = FeatureTagSkylineTor::RecallHammer;
}

namespace SubTagSkylineTorExposed
{
	const FName Start = n"Start";
	const FName StartFinal = n"StartFinal";
	const FName Idle = n"Idle";
	const FName End = n"End";
	const FName HitEnd = n"HitEnd";
}

struct FSkylineTorExposedSubTags
{
	UPROPERTY()
	FName Start = SubTagSkylineTorExposed::Start;
	UPROPERTY()
	FName StartFinal = SubTagSkylineTorExposed::StartFinal;
	UPROPERTY()
	FName Idle = SubTagSkylineTorExposed::Idle;
	UPROPERTY()
	FName End = SubTagSkylineTorExposed::End;
	UPROPERTY()
	FName EnHitEnd = SubTagSkylineTorExposed::HitEnd;
}

namespace SubTagSkylineTorChargeAttack
{
	const FName Telegraph = n"Telegraph";
	const FName Anticipation = n"Anticipation";
	const FName Action = n"Action";
	const FName Recover = n"Recover";
}

struct FSkylineTorChargeAttackSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagSkylineTorChargeAttack::Telegraph;
	UPROPERTY()
	FName Anticipation = SubTagSkylineTorChargeAttack::Anticipation;
	UPROPERTY()
	FName Action = SubTagSkylineTorChargeAttack::Action;
	UPROPERTY()
	FName Recover = SubTagSkylineTorChargeAttack::Recover;
}

namespace SubTagSkylineTorDiveAttack
{
	const FName Telegraph = n"Telegraph";
	const FName Dive = n"Dive";
	const FName Land = n"Land";
	const FName Leap = n"Leap";
	const FName LeapLand = n"LeapLand";
	const FName Recovery = n"Recovery";
}

struct FSkylineTorDiveAttackSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagSkylineTorDiveAttack::Telegraph;
	UPROPERTY()
	FName Dive = SubTagSkylineTorDiveAttack::Dive;
	UPROPERTY()
	FName Land = SubTagSkylineTorDiveAttack::Land;
	UPROPERTY()
	FName Leap = SubTagSkylineTorDiveAttack::Leap;
	UPROPERTY()
	FName LeapLand = SubTagSkylineTorDiveAttack::LeapLand;
	UPROPERTY()
	FName Recovery = SubTagSkylineTorDiveAttack::Recovery;
}

namespace SubTagSkylineTorPulseAttack
{
	const FName Fire = n"Fire";
}

struct FSkylineTorPulseAttackSubTags
{
	UPROPERTY()
	FName Fire = SubTagSkylineTorPulseAttack::Fire;
}

namespace SubTagSkylineTorStormAttack
{
	const FName Telegraph = n"Telegraph";
	const FName Attack = n"Attack";
	const FName Recovery = n"Recovery";
}

struct FSkylineTorStormAttackSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagSkylineTorStormAttack::Telegraph;
	UPROPERTY()
	FName Attack = SubTagSkylineTorStormAttack::Attack;
	UPROPERTY()
	FName Recovery = SubTagSkylineTorStormAttack::Recovery;
}

namespace SubTagSkylineTorEjectAttack
{
	const FName Pull = n"Pull";
	const FName Eject = n"Eject";
}

struct FSkylineTorEjectAttackSubTags
{
	UPROPERTY()
	FName Pull = SubTagSkylineTorEjectAttack::Pull;
	UPROPERTY()
	FName Eject = SubTagSkylineTorEjectAttack::Eject;
}

namespace SubTagSkylineTorWhirlwind
{
	const FName Telegraph = n"Telegraph";
	const FName Attack = n"Attack";
	const FName Recovery = n"Recovery";
}

struct FSkylineTorWhirlwindSubTags
{
	UPROPERTY()
	FName Telegraph = SubTagSkylineTorWhirlwind::Telegraph;
	UPROPERTY()
	FName Attack = SubTagSkylineTorWhirlwind::Attack;
	UPROPERTY()
	FName Recovery = SubTagSkylineTorWhirlwind::Recovery;
}



class UAnimInstanceSkylineTor : UAnimInstanceAIBase
{
	// Animations
	UPROPERTY(BlueprintReadOnly, Category = "Movement")
	FHazePlayBlendSpaceData MovementStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Movement")
	FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(BlueprintReadOnly, Category = "Movement")
	FHazePlayBlendSpaceData MovementStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Movement")
	FHazePlayBlendSpaceData MovementTurnInPlaceBS;

	UPROPERTY(BlueprintReadOnly, Category = "Hover")
	FHazePlayBlendSpaceData HoverStartBS;

	UPROPERTY(BlueprintReadOnly, Category = "Hover")
	FHazePlayBlendSpaceData HoverBS;

	UPROPERTY(BlueprintReadOnly, Category = "Hover")
	FHazePlayBlendSpaceData HoverStopBS;

	UPROPERTY(BlueprintReadOnly, Category = "Hover")
	FHazePlayBlendSpaceData HoverTurnInPlaceBS;

	UPROPERTY(Category = "HurtReaction")
	FHazePlaySequenceData HurtReaction;

	UPROPERTY(Category = "HurtReaction")
	FHazePlaySequenceData ExposedHurtReaction;

	UPROPERTY(Category = "HurtReaction")
	FHazePlaySequenceData ExposedHeavyHurtReaction;

	UPROPERTY(Category = "Interrupt")
	FHazePlaySequenceData Interrupt;

	UPROPERTY(Category = "WhipSlip")
	FHazePlaySequenceData WhipSlipStart;

	UPROPERTY(Category = "WhipSlip")
	FHazePlaySequenceData WhipSlipEnd;

	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttackStart;

	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttack;

	UPROPERTY(Category = "SwingAttack")
	FHazePlaySequenceData SwingAttackEnd;

	UPROPERTY(Category = "DebrisAttack")
	FHazePlaySequenceData DebrisAttack;

	UPROPERTY(Category = "RainDebrisAttack")
	FHazePlaySequenceData RainDebrisAttack;

	UPROPERTY(Category = "PulseAttack")
	FHazePlaySequenceData PulseAttack;

	UPROPERTY(Category = "PulseAttack")
	FHazePlayBlendSpaceData PulseWalk;

	UPROPERTY(Category = "PulseAttack")
	FHazePlayBlendSpaceData PulseAim;

	UPROPERTY(Category = "PulseAttack")
	FHazePlaySequenceData PulseShoot;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedStart;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedStartFinal;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedMH;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedEnd;

	UPROPERTY(Category = "Exposed")
	FHazePlaySequenceData ExposedHitEnd;

	UPROPERTY(Category = "Disarm")
	FHazePlaySequenceData Disarm;

	UPROPERTY(Category = "HammerVolley")
	FHazePlaySequenceData HammerVolley;

	UPROPERTY(Category = "HammerSpiral")
	FHazePlaySequenceData HammerSpiral;

	UPROPERTY(Category = "Mine")
	FHazePlaySequenceData DeployMine;

	UPROPERTY(Category = "Mine")
	FHazePlaySequenceData ControlMine;

	UPROPERTY(Category = "Death")
	FHazePlaySequenceData Death;

	UPROPERTY(Category = "Whirlwind")
	FHazePlaySequenceData WhirlwindTelegraph;

	UPROPERTY(Category = "Whirlwind")
	FHazePlaySequenceData Whirlwind;

	UPROPERTY(Category = "Whirlwind")
	FHazePlaySequenceData WhirlwindRecover;

	UPROPERTY(Category = "ChargeAttack")
	FHazePlaySequenceData ChargeAttackTelegraph;

	UPROPERTY(Category = "ChargeAttack")
	FHazePlaySequenceData ChargeAttackAnticipation;

	UPROPERTY(Category = "ChargeAttack")
	FHazePlaySequenceData ChargeAttackAction;

	UPROPERTY(Category = "ChargeAttack")
	FHazePlaySequenceData ChargeAttackRecover;

	UPROPERTY(Category = "SmashAttack")
	FHazePlaySequenceData SmashAttack;

	UPROPERTY(Category = "ClearArea")
	FHazePlaySequenceData ClearArea;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackTelegraph;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackDive;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackLand;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackLeap;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackLeapLand;

	UPROPERTY(Category = "DiveAttack")
	FHazePlaySequenceData DiveAttackRecovery;

	UPROPERTY(Category = "StormAttack")
	FHazePlaySequenceData StormAttackTelegraph;

	UPROPERTY(Category = "StormAttack")
	FHazePlaySequenceData StormAttackAttack;

	UPROPERTY(Category = "StormAttack")
	FHazePlaySequenceData StormAttackRecovery;

	UPROPERTY(Category = "EjectAttack")
	FHazePlaySequenceData EjectAttackPull;

	UPROPERTY(Category = "EjectAttack")
	FHazePlaySequenceData EjectAttackEject;

	UPROPERTY(Category = "BoloAttack")
	FHazePlaySequenceData BoloAttack;

	UPROPERTY(Category = "RecallHammer")
	FHazePlaySequenceData RecallHammer;

	
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorExposedSubTags ExposedSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorChargeAttackSubTags ChargeAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorDiveAttackSubTags DiveAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorStormAttackSubTags StormAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorEjectAttackSubTags EjectAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSkylineTorWhirlwindSubTags WhirlwindSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOpportunityAttackSuccess;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOpportunityAttackFail;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentOpportunityAttackResponse;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentOpportunityAttackMh;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FHazePlaySequenceData CurrentOpportunityFailResponse;

	UPROPERTY()
    bool bWasAlreadyMoving;
	
	UPROPERTY()
    bool bHovering;

	UPROPERTY()
    bool bHurtReaction;

	UPROPERTY()
    bool bHeavyHurtReaction;

	UPROPERTY()
    bool bHurtReactionInterrupted;

	UPROPERTY()
    bool bHeavyHurtReactionInterrupted;

	UPROPERTY()
	bool bPulseFired;

	UPROPERTY()
	bool bIsInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIK;

	// On Initialize
	USkylineTorHoverComponent HoverComp;
	USkylineTorDamageComponent DamageComp;
	UGravityBladePlayerOpportunityAttackComponent OpportunityAttackerComp;	
	UHazeMovementComponent MoveComp;
	UAnimFootTraceComponent FootTraceComp;

	bool bCutsceneDisableIK;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();

		// Default values, for editor preview		
		CurrentOpportunityAttackResponse = ExposedMH;
		CurrentOpportunityAttackMh = ExposedMH;
		CurrentOpportunityFailResponse = ExposedEnd;

		if(HazeOwningActor == nullptr)
			return;

		HoverComp = USkylineTorHoverComponent::Get(HazeOwningActor);
		DamageComp = USkylineTorDamageComponent::Get(HazeOwningActor);
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);

		FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);
	}	
	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (HazeOwningActor == nullptr)
			return;

        bWasAlreadyMoving = (HazeOwningActor.GetRawLastFrameTranslationVelocity().Size() >= 50.0);

		if(HoverComp != nullptr)
			bHovering = HoverComp.bHover;

		if(DamageComp != nullptr)
		{

			// Normal
			if(DamageComp.bHurtReactionInterrupted)
			{
				bHurtReactionInterrupted = true;
				DamageComp.bHurtReactionInterrupted = false;
			}
			else
			{
				bHurtReactionInterrupted = false;
				bHurtReaction = DamageComp.bHurtReaction;
			}
			 
			// Heavy
			if(DamageComp.bHeavyHurtReactionInterrupted)
			{
				bHeavyHurtReactionInterrupted = true;
				DamageComp.bHeavyHurtReactionInterrupted = false;
			}
			else
			{
				bHeavyHurtReactionInterrupted = false;
				bHeavyHurtReaction = DamageComp.bHeavyHurtReaction;
			}
		}
		if (MoveComp != nullptr)
			bIsInAir = MoveComp.IsInAir();

		if ((Game::Mio != nullptr) && (OpportunityAttackerComp == nullptr))
			OpportunityAttackerComp = UGravityBladePlayerOpportunityAttackComponent::Get(Game::Mio);
		if (OpportunityAttackerComp != nullptr)
		{
			bOpportunityAttackSuccess = OpportunityAttackerComp.bIsAttacking;
			bOpportunityAttackFail = OpportunityAttackerComp.bAttackFailed;
			if (OpportunityAttackerComp.CurrentSequence.Segments.IsValidIndex(OpportunityAttackerComp.CurrentSegment))
			{
				CurrentOpportunityAttackResponse = OpportunityAttackerComp.CurrentSequence.Segments[OpportunityAttackerComp.CurrentSegment].TargetAttackResponse;
				CurrentOpportunityAttackMh = OpportunityAttackerComp.CurrentSequence.Segments[OpportunityAttackerComp.CurrentSegment].TargetMh;
				CurrentOpportunityFailResponse = OpportunityAttackerComp.CurrentSequence.Segments[OpportunityAttackerComp.CurrentSegment].TargetFailResponse;
			}	
		}

		bPulseFired = CurrentSubTag == SubTagSkylineTorPulseAttack::Fire;
		
		// Foot IK Traces
		const bool bForceTraceAllFeet = CheckValueChangedAndSetBool(bEnableIK, ShouldUseIK(), EHazeCheckBooleanChangedDirection::FalseToTrue);
		if (bCutsceneDisableIK)
			bEnableIK = false;

		if (bEnableIK && FootTraceComp != nullptr)
			FootTraceComp.TraceFeet(IKFeetPlacementData, bForceTraceAllFeet);

		bCutsceneDisableIK = HazeOwningActor.bIsControlledByCutscene;

		Super::BlueprintUpdateAnimation(DeltaTime);
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag) override
	{
		if (Tag == FeatureTagSkylineTor::ClearArea)
			return ClearArea.Sequence;
		if (Tag == FeatureTagSkylineTor::Interrupt)
			return Interrupt.Sequence;
		if (Tag == FeatureTagSkylineTor::HammerVolley)
			return HammerVolley.Sequence;
		if (Tag == FeatureTagSkylineTor::HammerSpiral)
			return HammerSpiral.Sequence;
		if (Tag == FeatureTagSkylineTor::SwingAttack)
			return SwingAttack.Sequence;
		if (Tag == FeatureTagSkylineTor::RainDebrisAttack)
			return RainDebrisAttack.Sequence;

		if (Tag == FeatureTagSkylineTor::ChargeAttack)
		{
			if(SubTag == SubTagSkylineTorChargeAttack::Telegraph)
				return ChargeAttackTelegraph.Sequence;
			if(SubTag == SubTagSkylineTorChargeAttack::Anticipation)
				return ChargeAttackAnticipation.Sequence;
			if(SubTag == SubTagSkylineTorChargeAttack::Action)
				return ChargeAttackAction.Sequence;
			if(SubTag == SubTagSkylineTorChargeAttack::Recover)
				return ChargeAttackRecover.Sequence;
		}

		if (Tag == FeatureTagSkylineTor::DiveAttack)
		{
			if(SubTag == SubTagSkylineTorDiveAttack::Telegraph)
				return DiveAttackTelegraph.Sequence;
			if(SubTag == SubTagSkylineTorDiveAttack::Dive)
				return DiveAttackDive.Sequence;
			if(SubTag == SubTagSkylineTorDiveAttack::Land)
				return DiveAttackLand.Sequence;
			if(SubTag == SubTagSkylineTorDiveAttack::Leap)
				return DiveAttackLeap.Sequence;
		}

		if (Tag == FeatureTagSkylineTor::SmashAttack)
			return SmashAttack.Sequence;

		if (Tag == FeatureTagSkylineTor::StormAttack)
		{
			if(SubTag == SubTagSkylineTorStormAttack::Telegraph)
				return StormAttackTelegraph.Sequence;
			if(SubTag == SubTagSkylineTorStormAttack::Attack)
				return StormAttackAttack.Sequence;
			if(SubTag == SubTagSkylineTorStormAttack::Recovery)
				return StormAttackRecovery.Sequence;
		}

		if (Tag == FeatureTagSkylineTor::Whirlwind)
		{
			if(SubTag == SubTagSkylineTorWhirlwind::Telegraph)
				return WhirlwindTelegraph.Sequence;
			if(SubTag == SubTagSkylineTorWhirlwind::Attack)
				return Whirlwind.Sequence;
			if(SubTag == SubTagSkylineTorWhirlwind::Recovery)
				return WhirlwindRecover.Sequence;
		}

		if (Tag == FeatureTagSkylineTor::BoloAttack)
		{
			return BoloAttack.Sequence;
		}
		
		return nullptr;
	}

	bool ShouldUseIK()
	{
		if (CurrentFeatureTag == FeatureTagSkylineTor::OpportunityAttack)
			return false;

		return true;
	}

}	