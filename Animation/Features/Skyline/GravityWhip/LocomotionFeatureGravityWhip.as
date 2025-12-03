struct FLocomotionFeatureGravityWhipAnimData
{
	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData WhipVar1;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData WhipVar1a;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData WhipVar2;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData WhipVar2a;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData WhipVar3;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData AirWhipVar1;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData AirWhipVar1a;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData AirWhipVar2;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData AirWhipVar2a;

	UPROPERTY(Category = "GravityWhip|Whip")
	FHazePlaySequenceData AirWhipVar3;

	UPROPERTY(Category = "GravityWhip|Attach/Pull")
	FHazePlaySequenceData AttachVar1;

	UPROPERTY(Category = "GravityWhip|Attach/Pull")
	FHazePlaySequenceData AttachVar1a;

	UPROPERTY(Category = "GravityWhip|Attach/Pull")
	FHazePlaySequenceData AttachVar2;

	UPROPERTY(Category = "GravityWhip|Attach/Pull")
	FHazePlaySequenceData PullVar1a;

	UPROPERTY(Category = "GravityWhip|Mh")
	FHazePlayBlendSpaceData HoldMhBS;

	UPROPERTY(Category = "GravityWhip|Mh")
	FHazePlayBlendSpaceData LassoMhBS;

	UPROPERTY(Category = "GravityWhip|Throw")
	FHazePlaySequenceData ThrowVar1;

	UPROPERTY(Category = "GravityWhip|Hit Glory Kill")
	TArray<FGravityWhipGloryKillSequence> GloryKills;

	UPROPERTY(Category = "GravityWhip|TorHammer")
	FHazePlaySequenceData TorHammerEnter;
	UPROPERTY(Category = "GravityWhip|TorHammer")
	FHazePlaySequenceData TorHammerAttack;

	int SelectRandomGloryKill(
		EGravityWhipGloryKillCondition Condition,
		float Distance,
		int SkipGloryKillIndex = -1,
		bool bGuaranteedTrigger = false,
		) const
	{
		float TotalChance = 0.0;
		for (int i = 0, Count = GloryKills.Num(); i < Count; ++i)
		{
			const FGravityWhipGloryKillSequence& GloryKill = GloryKills[i];
			if (GloryKill.Condition != Condition)
				continue;
			if (Distance > GloryKill.MaximumRange)
				continue;
			if (i == SkipGloryKillIndex)
				continue;

			TotalChance += GloryKill.TriggerChance;
		}
		
		if (bGuaranteedTrigger && TotalChance <= 0.0 && SkipGloryKillIndex != -1)
		{
			// If we want to guarantee a glory kill but we didn't find one, then loosen the skip condition
			return SelectRandomGloryKill(Condition, Distance, -1, true);
		}

		if (TotalChance <= 0)
			return -1;

		float ChosenPct;
		if (bGuaranteedTrigger)
			ChosenPct = Math::RandRange(0.0, TotalChance);
		else
			ChosenPct = Math::RandRange(0.0, Math::Max(1.0, TotalChance));

		for (int i = 0, Count = GloryKills.Num(); i < Count; ++i)
		{
			const FGravityWhipGloryKillSequence& GloryKill = GloryKills[i];
			if (GloryKill.Condition != Condition)
				continue;
			if (Distance > GloryKill.MaximumRange)
				continue;
			if (i == SkipGloryKillIndex)
				continue;

			if (ChosenPct <= GloryKill.TriggerChance)
				return i;
			else
				ChosenPct -= GloryKill.TriggerChance;
		}

		return -1;
	}
}

enum EGravityWhipGloryKillCondition
{
	Hit,
	ThrowAtFloor,
	ThrowAtWall,
}

struct FGravityWhipGloryKillSequence
{
	UPROPERTY()
	EGravityWhipGloryKillCondition Condition = EGravityWhipGloryKillCondition::Hit;

	/**
	 * Trigger chance.
	 * 
	 * OBS: This is additive to all the other glory kills with the same condition.
	 * That is, two glory kills both with 0.25 chance means there is a 50% chance overall to do a glory kill.
	 */
	UPROPERTY()
	float TriggerChance = 1.0;

	// Maximum range to do this glory kill
	UPROPERTY()
	float MaximumRange = 10000.0;

	// Socket that the whip attaches to on the enforcer while playing the animation
	UPROPERTY()
	FName WhipAttachSocket;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	// How long the player stays in strafe after starting this glory kill
	UPROPERTY()
	float StrafeDuration = 0.0;

	// Whether the enemy should be moved to Zoe while the glory kill is happening
	UPROPERTY()
	bool bMoveEnemyToZoe = false;

	UPROPERTY()
	FHazePlaySequenceData PlayerAnimation;
	UPROPERTY()
	FHazePlaySequenceData WhipAnimation;
	UPROPERTY()
	FHazePlaySequenceData EnforcerAnimation;

	bool IsValid()
	{
		return PlayerAnimation.Sequence != nullptr;
	}
}

class ULocomotionFeatureGravityWhip : UHazeLocomotionFeatureBase
{
	default Tag = n"GravityWhip";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGravityWhipAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
