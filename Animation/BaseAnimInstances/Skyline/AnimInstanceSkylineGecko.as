namespace FeatureTagGecko
{
	const FName Locomotion = n"Locomotion";
	const FName Strafing = n"Strafing";
	const FName Dodge = n"Dodge";
	const FName WallClimb = n"WallClimb";
	const FName MeleeAttack = n"MeleeAttack";
	const FName RangedAttack = n"RangedAttack";
	const FName ResistWhip = n"ResistWhip";
	const FName TakeDamage = n"TakeDamage";
	const FName Overturned = n"Overturned";
	const FName Taunts = n"Taunts";
	const FName Stunned = n"Stunned";
	const FName GrabbedByWhip = n"GrabbedByWhip";
	const FName ThrownByWhip = n"ThrownByWhip";
	const FName PounceAttack = n"PounceAttack";
	const FName ConstrainPlayer = n"ConstrainPlayer";
	const FName Jump = n"Jump";
	const FName Death = n"Death";
}

struct FGeckoFeatureTags
{
	UPROPERTY()
	FName Locomotion = FeatureTagGecko::Locomotion;
	UPROPERTY()
	FName Strafing = FeatureTagGecko::Strafing;
	UPROPERTY()
	FName Dodge = FeatureTagGecko::Dodge;
	UPROPERTY()
	FName WallClimb = FeatureTagGecko::WallClimb;
	UPROPERTY()
	FName MeleeAttack = FeatureTagGecko::MeleeAttack;
	UPROPERTY()
	FName RangedAttack = FeatureTagGecko::RangedAttack;
	UPROPERTY()
	FName ResistWhip = FeatureTagGecko::ResistWhip;
	UPROPERTY()
	FName TakeDamage = FeatureTagGecko::TakeDamage;
	UPROPERTY()
	FName Stunned = FeatureTagGecko::Stunned;
	UPROPERTY()
	FName Overturned = FeatureTagGecko::Overturned;
	UPROPERTY()
	FName Taunts = FeatureTagGecko::Taunts;
	UPROPERTY()
	FName GrabbedByWhip = FeatureTagGecko::GrabbedByWhip;
	UPROPERTY()
	FName ThrownByWhip = FeatureTagGecko::ThrownByWhip;
	UPROPERTY()
	FName PounceAttack = FeatureTagGecko::PounceAttack;
	UPROPERTY()
	FName ConstrainPlayer = FeatureTagGecko::ConstrainPlayer;
	UPROPERTY()
	FName Jump = FeatureTagGecko::Jump;
	UPROPERTY()
	FName Death = FeatureTagGecko::Death;
}

namespace SubTagGeckoLocomotion
{
	const FName Idle = n"Idle";
	const FName Walk = n"Walk";
	const FName TurnInPlace = n"TurnInPlace";
}

struct FGeckoLocomotionSubTags
{
	UPROPERTY()
	FName Idle = SubTagGeckoLocomotion::Idle;
	UPROPERTY()
	FName Walk = SubTagGeckoLocomotion::Walk;
	UPROPERTY()
	FName TurnInPlace = SubTagGeckoLocomotion::TurnInPlace;
}

namespace SubTagGeckoMeleeAttack
{
	const FName MeleeAttackTelegraph = n"MeleeAttackTelegraph";
	const FName MeleeAttackStart = n"MeleeAttackStart";
	const FName MeleeAttack = n"MeleeAttack";
	const FName MeleeAttackExit = n"MeleeAttackExit";
}

struct FGeckoMeleeAttackSubTags
{
	UPROPERTY()
	FName MeleeAttackTelegraph = SubTagGeckoMeleeAttack::MeleeAttackTelegraph;
	UPROPERTY()
	FName MeleeAttackStart = SubTagGeckoMeleeAttack::MeleeAttackStart;
	UPROPERTY()
	FName MeleeAttack = SubTagGeckoMeleeAttack::MeleeAttack;
	UPROPERTY()
	FName MeleeAttackExit = SubTagGeckoMeleeAttack::MeleeAttackExit;
}

namespace SubTagGeckoRangedAttack
{
	const FName RangedAttackTelegraph = n"RangedAttackTelegraph";
	const FName RangedAttack = n"RangedAttack";
}

struct FGeckoRangedAttackSubTags
{
	UPROPERTY()
	FName RangedAttackTelegraph = SubTagGeckoRangedAttack::RangedAttackTelegraph;
	UPROPERTY()
	FName RangedAttack = SubTagGeckoRangedAttack::RangedAttack;
}

namespace SubTagGeckoOverturned
{
	const FName EnterFalling = n"EnterFalling";
	const FName FallingMh = n"FallingMh";
	const FName Overturned = n"Overturned";
	const FName OverturnedRecover = n"OverturnedRecover";	
	const FName OverturnedReturn = n"OverturnedReturn";
}

struct FGeckoOverturnedSubTags
{
	UPROPERTY()
	FName EnterFalling = SubTagGeckoOverturned::EnterFalling;
	UPROPERTY()
	FName FallingMh = SubTagGeckoOverturned::FallingMh;
	UPROPERTY()
	FName Overturned = SubTagGeckoOverturned::Overturned;
	UPROPERTY()
	FName OverturnedRecover = SubTagGeckoOverturned::OverturnedRecover;
	UPROPERTY()
	FName OverturnedReturn = SubTagGeckoOverturned::OverturnedReturn;
}

namespace SubTagGeckoTaunts
{
	const FName EntryBeforeJump = n"EntryBeforeJump";
	const FName SpotTarget = n"SpotTarget";
	const FName TrackTarget = n"TrackTarget";
}

struct FGeckoTauntSubTags
{
	UPROPERTY()
	FName EntryBeforeJump = SubTagGeckoTaunts::EntryBeforeJump;
	UPROPERTY()
	FName SpotTarget = SubTagGeckoTaunts::SpotTarget;
	UPROPERTY()
	FName TrackTarget = SubTagGeckoTaunts::TrackTarget;
}

namespace SubTagGeckoStunned
{
	const FName Stunned = n"Stunned";
	const FName Recover = n"Recover";
}

struct FGeckoStunnedSubTags
{
	UPROPERTY()
	FName Stunned = SubTagGeckoStunned::Stunned;
	UPROPERTY()
	FName Recover = SubTagGeckoStunned::Recover;
}

namespace SubTagGeckoPounceAttack
{
	const FName Pounce = n"Pounce";
	const FName Land = n"Land";
}

struct FGeckoPounceAttackSubTags
{
	UPROPERTY()
	FName Pounce = SubTagGeckoPounceAttack::Pounce;
	UPROPERTY()
	FName Land = SubTagGeckoPounceAttack::Land;
}

namespace SubTagGeckoJump
{
	const FName Jump = n"Jump";
	const FName Land = n"Land";
}

struct FGeckoJumpSubTags
{
	UPROPERTY()
	FName Jump = SubTagGeckoJump::Jump;
	UPROPERTY()
	FName Land = SubTagGeckoJump::Land;
}

namespace SubTagGeckoConstrainPlayer
{
	const FName Attack = n"Attack";
	const FName Constrain = n"Constrain";
	const FName AfterKill = n"AfterKill";
	const FName ThrownOff = n"ThrownOff";
}

struct FGeckoConstrainPlayerSubTags
{
	UPROPERTY()
	FName Attack = SubTagGeckoConstrainPlayer::Attack;
	UPROPERTY()
	FName Constrain = SubTagGeckoConstrainPlayer::Constrain;
	UPROPERTY()
	FName AfterKill = SubTagGeckoConstrainPlayer::AfterKill;
	UPROPERTY()
	FName ThrownOff = SubTagGeckoConstrainPlayer::ThrownOff;
}


class UAnimInstanceGecko : UAnimInstanceAIBase
{
	// Animations

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayRndSequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData MhAdditive;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlaySequenceData Walk;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData MhBS;
	
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData WalkBwdBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData WalkBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData TrottBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData RunBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData StrafeBS;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Taunts")
    FHazePlayRndSequenceData EntryBeforeJump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Dodge")
    FHazePlaySequenceData DodgeStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Dodge")
    FHazePlaySequenceData Dodge;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Dodge")
    FHazePlaySequenceData DodgeExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData JumpStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData JumpMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData Landing;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData JumpSeq;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|WallClimb")
    FHazePlaySequenceData WallClimb;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeAttack")
    FHazePlaySequenceData MeleeAttackTelegraph;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeAttack")
    FHazePlaySequenceData MeleeAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeAttack")
    FHazePlaySequenceData MeleeAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeAttack")
    FHazePlaySequenceData MeleeAttackRecover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|MeleeAttack")
    FHazePlaySequenceData PounceAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ConstrainPlayer")
    FHazePlaySequenceData ConstrainPlayerAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ConstrainPlayer")
    FHazePlaySequenceData ConstrainPlayerStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ConstrainPlayer")
    FHazePlaySequenceData ConstrainPlayerMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ConstrainPlayer")
    FHazePlaySequenceData ConstrainPlayerEndAfterKill;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ConstrainPlayer")
    FHazePlaySequenceData ConstrainPlayerEndThrownOff;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|RangedAttack")
    FHazePlaySequenceData RangedAttackTelegraph;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|RangedAttack")
    FHazePlaySequenceData RangedAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|RangedAttack")
    FHazePlaySequenceData RangedAttackRecover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|ResistWhip")
    FHazePlayRndSequenceData ResistWhip;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|TakeDamage")
    FHazePlayRndSequenceData TakeDamage;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Stunned")
    FHazePlaySequenceData StunnedStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Stunned")
    FHazePlaySequenceData StunnedMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Stunned")
    FHazePlaySequenceData StunnedRecover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlaySequenceData OverturnedEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlaySequenceData OverturnedFallingMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlaySequenceData OverturnedLanding;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlayRndSequenceData OverturnedMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlaySequenceData OverturnedRecover;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Overturned")
    FHazePlaySequenceData CielingJump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grabbed")
    FHazePlaySequenceData GrabbedMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grabbed")
    FHazePlaySequenceData ThrownMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Death")
    FHazePlayRndSequenceData Death;

	// FeatureTags and SubTags

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoLocomotionSubTags LocomotionSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoMeleeAttackSubTags MeleeAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoRangedAttackSubTags RangedAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoOverturnedSubTags OverturnedSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoTauntSubTags TauntSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoStunnedSubTags StunnedSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoPounceAttackSubTags PounceAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoConstrainPlayerSubTags ConstrainPlayerSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FGeckoJumpSubTags JumpSubTags;

	// Components 

	UBasicAITargetingComponent TargetComp;
	USkylineGeckoBlobComponent BlobComp;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	USkylineGeckoComponent GeckoComp;

	// Custom variables
	
	AHazeActor Target;

	UPROPERTY(Transient)
	FVector TargetDirection;

	UPROPERTY(Transient)
	FVector TargetDirectionAngle;

	UPROPERTY(Transient)
	FVector TargetWorldLocation;

	UPROPERTY(Transient)
	FVector TargetFocusLocation;

	UPROPERTY(Transient)
	float IdlePlayRate = 0.0;

	UPROPERTY(Transient)
	float WalkingPlayRate = 1.0;

	UPROPERTY(Transient)
	float TrottingPlayRate = 1.0;

	UPROPERTY(Transient)
	float RunningPlayRate = 1.0;

	UPROPERTY(Transient)
	float WalkingBwdPlayRate = 1.0;

	UPROPERTY(Transient, Category = "SlopeAlign")
	FVector SlopeOffset;

	UPROPERTY(Transient, Category = "SlopeAlign")
	FRotator SlopeRotation;

	UPROPERTY()
	float LookAtAlphaMultiplier;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
        Super::BlueprintInitializeAnimation();

		if (HazeOwningActor == nullptr)
			return; // Editor preview

		TargetComp = UBasicAITargetingComponent::GetOrCreate(HazeOwningActor);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(HazeOwningActor);
		BlobComp = USkylineGeckoBlobComponent::GetOrCreate(HazeOwningActor);
    }

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if	(TargetComp == nullptr)
			return;

        Super::BlueprintUpdateAnimation(DeltaTime);

		WalkingPlayRate = SpeedForward / 200;
		TrottingPlayRate = SpeedForward / 400;
		RunningPlayRate = SpeedForward / 950;
		WalkingBwdPlayRate = SpeedForward / -200;
		
		if (BlobComp.CurrentTarget != nullptr)
		{	
			Target = BlobComp.CurrentTarget;
			TargetWorldLocation = Target.ActorLocation;	
			TargetFocusLocation = Target.FocusLocation + Target.ActorUpVector * GeckoComp.FocusOffset;
		}

		else if (TargetComp.Target != nullptr)
		{
			Target = TargetComp.Target;
			TargetWorldLocation = Target.ActorLocation;
			TargetFocusLocation = Target.FocusLocation + Target.ActorUpVector * GeckoComp.FocusOffset;
		}	

		if (SlopeAlignComp == nullptr)
		{
			if (UHazeMovementComponent::Get(HazeOwningActor) != nullptr)
				SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		}
		else
			SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.5);
		

		if (IsCurrentFeatureTag(FeatureTagGecko::Overturned) 		|| 
			IsCurrentFeatureTag(FeatureTagGecko::MeleeAttack)		|| 
			IsCurrentFeatureTag(FeatureTagGecko::Stunned)			|| 
			IsCurrentFeatureTag(FeatureTagGecko::PounceAttack))
			LookAtAlphaMultiplier = 0;
		else
			LookAtAlphaMultiplier = 1;
			//LookAtAlphaMultiplier = Math::FInterpTo(0, 1, DeltaTime, 50);

		//Print("LookAtAlphaMultiplier: " + LookAtAlphaMultiplier, 0.f);

		//PrintToScreenScaled("Tag: " + CurrentFeatureTag);
		//PrintToScreenScaled("SubTag: " + CurrentSubTag);
    }


	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
		Super::LogAnimationTemporalData(TemporalLog);
		TemporalLog.Value("Target", Target);
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag) override
	{
		if (Tag == FeatureTagGecko::PounceAttack)
			return PounceAttack.Sequence;
		if (Tag == FeatureTagGecko::ConstrainPlayer)
		{
			if (SubTag == SubTagGeckoConstrainPlayer::AfterKill)
				return ConstrainPlayerEndAfterKill.Sequence;
			if (SubTag == SubTagGeckoConstrainPlayer::ThrownOff)
				return ConstrainPlayerEndThrownOff.Sequence;
			return ConstrainPlayerMh.Sequence;
		}
		return nullptr;
	}
}