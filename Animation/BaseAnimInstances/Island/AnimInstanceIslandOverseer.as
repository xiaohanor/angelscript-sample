namespace FeatureTagIslandOverseer
{
	const FName Idle = n"Idle";
	const FName DeployRoller = n"DeployRoller";
	const FName RemoveRoller = n"RemoveRoller";
	const FName Peek = n"Peek";
	const FName DeployEye = n"DeployEye";
	const FName GrabEye = n"GrabEye";
	const FName Flood = n"Flood";
	const FName Move = n"Move";
	const FName Advance = n"Advance";
	const FName MissileAttack = n"MissileAttack";
	const FName BeamAttack = n"BeamAttack";
	const FName Pushback = n"Pushback";
	const FName Drop = n"Drop";
	const FName DoorAcid = n"DoorAcid";
	const FName Tremor = n"Tremor";
	const FName DoorShake = n"DoorShake";
	const FName Haymaker = n"Haymaker";
	const FName LaserBombAttack = n"LaserBombAttack";
	const FName Block = n"Block";
}

struct FIslandOverseerFeatureTags
{
	UPROPERTY()
	FName Idle = FeatureTagIslandOverseer::Idle;
	UPROPERTY()
	FName DeployRoller = FeatureTagIslandOverseer::DeployRoller;
	UPROPERTY()
	FName RemoveRoller = FeatureTagIslandOverseer::RemoveRoller;
	UPROPERTY()
	FName Peek = FeatureTagIslandOverseer::Peek;
	UPROPERTY()
	FName DeployEye = FeatureTagIslandOverseer::DeployEye;
	UPROPERTY()
	FName GrabEye = FeatureTagIslandOverseer::GrabEye;
	UPROPERTY()
	FName Flood = FeatureTagIslandOverseer::Flood;
	UPROPERTY()
	FName Move = FeatureTagIslandOverseer::Move;
	UPROPERTY()
	FName Advance = FeatureTagIslandOverseer::Advance;
	UPROPERTY()
	FName MissileAttack = FeatureTagIslandOverseer::MissileAttack;
	UPROPERTY()
	FName BeamAttack = FeatureTagIslandOverseer::BeamAttack;
	UPROPERTY()
	FName Pushback = FeatureTagIslandOverseer::Pushback;
	UPROPERTY()
	FName Drop = FeatureTagIslandOverseer::Drop;
	UPROPERTY()
	FName DoorAcid = FeatureTagIslandOverseer::DoorAcid;
	UPROPERTY()
	FName Tremor = FeatureTagIslandOverseer::Tremor;
	UPROPERTY()
	FName DoorShake = FeatureTagIslandOverseer::DoorShake;
	UPROPERTY()
	FName Haymaker = FeatureTagIslandOverseer::Haymaker;
	UPROPERTY()
	FName LaserBombAttack = FeatureTagIslandOverseer::LaserBombAttack;
	UPROPERTY()
	FName Block = FeatureTagIslandOverseer::Block;
}

namespace SubTagIslandOverseerDoorShake
{
	const FName Default = n"Default";
	const FName Doors = n"Doors";
}

struct FIslandOverseerDoorShakeSubTags
{
	UPROPERTY()
	FName Default = SubTagIslandOverseerDoorShake::Default;
	UPROPERTY()
	FName Doors = SubTagIslandOverseerDoorShake::Doors;
}

namespace SubTagIslandOverseerDeployRoller
{
	const FName DeployLeft = n"DeployLeft";
	const FName DeployRight = n"DeployRight";
}

struct FIslandOverseerDeployRollerSubTags
{
	UPROPERTY()
	FName DeployLeft = SubTagIslandOverseerDeployRoller::DeployLeft;
	UPROPERTY()
	FName DeployRight = SubTagIslandOverseerDeployRoller::DeployRight;
}

namespace SubTagIslandOverseerMissileAttack
{
	const FName Start = n"Start";
	const FName Loop = n"Loop";
	const FName End = n"End";
}

struct FIslandOverseerMissileAttackSubTags
{
	UPROPERTY()
	FName Start = SubTagIslandOverseerMissileAttack::Start;
	UPROPERTY()
	FName Loop = SubTagIslandOverseerMissileAttack::Loop;
	UPROPERTY()
	FName End = SubTagIslandOverseerMissileAttack::End;
}

namespace SubTagIslandOverseerFlood
{
	const FName Idle = n"Idle";
	const FName Platform = n"Platform";
	const FName PlatformRight = n"PlatformRight";
	const FName PlatformLeft = n"PlatformLeft";
	const FName End = n"End";
}

struct FIslandOverseerFloodSubTags
{
	UPROPERTY()
	FName Idle = SubTagIslandOverseerFlood::Idle;
	UPROPERTY()
	FName Platform = SubTagIslandOverseerFlood::Platform;
	UPROPERTY()
	FName PlatformLeft = SubTagIslandOverseerFlood::PlatformLeft;
	UPROPERTY()
	FName PlatformRight = SubTagIslandOverseerFlood::PlatformRight;
	UPROPERTY()
	FName End = SubTagIslandOverseerFlood::End;
}

namespace SubTagIslandOverseerPeek
{
	const FName Start = n"Start";
	const FName End = n"End";
}

struct FIslandOverseerPeekSubTags
{
	UPROPERTY()
	FName Start = SubTagIslandOverseerPeek::Start;
	UPROPERTY()
	FName End = SubTagIslandOverseerPeek::End;
}

namespace SubTagIslandOverseerLaserBombAttack
{
	const FName Start = n"Start";
	const FName End = n"End";
}

struct FIslandOverseerLaserBombAttackSubTags
{
	UPROPERTY()
	FName Start = SubTagIslandOverseerLaserBombAttack::Start;
	UPROPERTY()
	FName End = SubTagIslandOverseerLaserBombAttack::End;
}


class UAnimInstanceIslandOverseer : UAnimInstanceAIBase
{
	// Animations

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Idle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DeployRollerLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DeployRollerRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData RemoveRollerLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData RemoveRollerRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData PeekStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData PeekLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData PeekEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DeployEye;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FloodStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FloodMH;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FloodEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FloodPlatform;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Move;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Advance;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReactionTakeDamageLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReactionTakeDamageRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData HitReactionTakeDamageProfile;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData HitReactionTakeDamageCutHead;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayRndSequenceData HitReactionTakeDamageCutHeadDead;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReactionMoveLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReactionMoveRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData VisorOpen;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData VisorMH;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData VisorClose;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MissileAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MissileAttackLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MissileAttackEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BeamAttack;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoistUpStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoistUpLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoistUpEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoistUpPlatformLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HoistUpPlatformRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Pushback;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData GrabEye;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorAcidStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorAcidLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorAcidEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Tremor;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayRndSequenceData DoorShake;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorShakeDoors;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Haymaker;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData LaserBombAttackStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlayBlendSpaceData LaserBombAttackLoop;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData LaserBombAttackEnd;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorCutHeadIdle;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorCutHeadStart;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorCutHeadDefeated;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData DoorCutHeadDecapitate;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Block;



	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerFeatureTags FeatureTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerDeployRollerSubTags DeployRollerSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerMissileAttackSubTags MissileAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerFloodSubTags FloodSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerPeekSubTags PeekSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerLaserBombAttackSubTags LaserBombAttackSubTags;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FIslandOverseerDoorShakeSubTags DoorShakeSubTags;



	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOpenVisor;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOverrideVisor;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionTakeDamageLeft;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionTakeDamageRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionTakeDamageProfile;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionTakeDamageCutHead;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionTakeDamageCutHeadDead;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionMoveLeft;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReactionMoveRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHoisting;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHoistUp;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDoorAttacks;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDoorHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bDoorCutHead;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EIslandOverseerCutHeadState CutHeadState;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CutHeadPlayRate;

	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerTakeDamageComponent TakeDamageComp;
	UIslandOverseerFloodAttackComponent FloodAttackComp;
	UIslandOverseerHoistComponent HoistComp;
	UIslandOverseerDoorComponent DoorComp;

	// On Initialize
	
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		if(HazeOwningActor == nullptr)
			return;

		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(HazeOwningActor);
		TakeDamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(HazeOwningActor);
		FloodAttackComp = UIslandOverseerFloodAttackComponent::GetOrCreate(HazeOwningActor);
		HoistComp = UIslandOverseerHoistComponent::GetOrCreate(HazeOwningActor);
		DoorComp = UIslandOverseerDoorComponent::GetOrCreate(HazeOwningActor);
	}	
	
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if(VisorComp != nullptr)
		{
			bOpenVisor = (VisorComp.bOpen || VisorComp.bOpening) && !VisorComp.bClosing;
			bOverrideVisor = !VisorComp.bDisabled;
		}

		if(TakeDamageComp != nullptr)
		{
			bHitReactionTakeDamageLeft = TakeDamageComp.bHitReactionTakeDamageLeft;
			bHitReactionTakeDamageRight = TakeDamageComp.bHitReactionTakeDamageRight;
			bHitReactionTakeDamageProfile = TakeDamageComp.bHitReactionTakeDamageProfile;
			bHitReactionTakeDamageCutHead = TakeDamageComp.bHitReactionTakeDamageCutHead;
			bHitReactionTakeDamageCutHeadDead = TakeDamageComp.bHitReactionTakeDamageCutHeadDead;
			bHitReactionMoveLeft = TakeDamageComp.bHitReactionMoveLeft;
			bHitReactionMoveRight = TakeDamageComp.bHitReactionMoveRight;
		}

		if(HoistComp != nullptr)
		{
			bHoisting = HoistComp.bHoisted;
			bHoistUp = HoistComp.bHoistUp;
		}

		if(DoorComp != nullptr)
		{
			CutHeadState = DoorComp.CutHeadState;
			CutHeadPlayRate = DoorComp.CutHeadPlayRate;
			bDoorAttacks = DoorComp.bDoorAttack;
			bDoorHitReaction = DoorComp.bHitReaction;
			bDoorCutHead = DoorComp.bDoorCutHead;
		}
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag) override
	{
		if (Tag == FeatureTagIslandOverseer::BeamAttack)
			return BeamAttack.Sequence;
		if (Tag == FeatureTagIslandOverseer::Haymaker)
			return Haymaker.Sequence;
		if (Tag == FeatureTagIslandOverseer::Tremor)
			return Tremor.Sequence;
		if(Tag == FeatureTagIslandOverseer::Peek)
		{
			if (SubTag == SubTagIslandOverseerPeek::Start)
				return PeekStart.Sequence;
			if (SubTag == SubTagIslandOverseerPeek::End)
				return PeekEnd.Sequence;
		}
		if(Tag == FeatureTagIslandOverseer::DoorShake)
		{
			if(SubTag == SubTagIslandOverseerDoorShake::Default)
				return DoorShake.RandomAnimation;
			if(SubTag == SubTagIslandOverseerDoorShake::Doors)
				return DoorShakeDoors.Sequence;
		}
		if(Tag == FeatureTagIslandOverseer::DeployRoller)
		{
			if(SubTag == SubTagIslandOverseerDeployRoller::DeployLeft)
				return DeployRollerLeft.Sequence;
			if(SubTag == SubTagIslandOverseerDeployRoller::DeployRight)
				return DeployRollerRight.Sequence;
		}
		return nullptr;
	}
}	