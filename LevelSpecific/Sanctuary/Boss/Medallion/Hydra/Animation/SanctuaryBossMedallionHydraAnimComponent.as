struct FSanctuaryBossMedallionHydraAnimRequest
{
	EFeatureTagMedallionHydra Tag;
	EFeatureSubTagMedallionHydra SubTag;
	float CustomPlayRate = 1.0;
}

class USanctuaryBossMedallionHydraAnimComponent : UActorComponent
{
	private FSanctuaryBossMedallionHydraAnimRequest CurrentAnimationRequest;
	private float CurrentAnimationDuration = 0.0;

	private ASanctuaryBossMedallionHydra MedallionHydra;
	float CachedMioZoeStrangleAlpha = 0.0;
	private AHazePlayerCharacter CachedMio;
	private AHazePlayerCharacter CachedZoe;
	private UMedallionPlayerComponent MioMedallionComp;
	private UMedallionPlayerComponent ZoeMedallionComp;
	private UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MedallionHydra = Cast<ASanctuaryBossMedallionHydra>(Owner);
		CurrentAnimationRequest.Tag = EFeatureTagMedallionHydra::None_Idling;
		CurrentAnimationRequest.SubTag = EFeatureSubTagMedallionHydra::None;
		CachedMio = Game::Mio;
		CachedZoe = Game::Zoe;
		MioMedallionComp = UMedallionPlayerComponent::GetOrCreate(CachedMio);
		ZoeMedallionComp = UMedallionPlayerComponent::GetOrCreate(CachedZoe);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(CachedMio);
	}

	EFeatureTagMedallionHydra GetFeatureTag() const
	{
		return CurrentAnimationRequest.Tag;
	}

	EFeatureSubTagMedallionHydra GetSubFeatureTag() const
	{
		return CurrentAnimationRequest.SubTag;		
	}

	bool AnyPlayerFlying() const
	{
		if (MioMedallionComp == nullptr || ZoeMedallionComp == nullptr)
			return false;
		return MioMedallionComp.IsMedallionCoopFlying() || ZoeMedallionComp.IsMedallionCoopFlying();
	}

	bool IsInBallistaPhase() const
	{
		if (RefsComp == nullptr || RefsComp.Refs == nullptr || RefsComp.Refs.HydraAttackManager == nullptr)
			return false;
		return RefsComp.Refs.HydraAttackManager.Phase >= EMedallionPhase::Ballista1 && RefsComp.Refs.HydraAttackManager.Phase <= EMedallionPhase::Skydive;
	}

	float GetCustomPlayRate() const
	{
		return CurrentAnimationRequest.CustomPlayRate;	
	}

	UFUNCTION(NotBlueprintCallable)
	float GetAnimationDuration() const
	{
		return CurrentAnimationDuration;
	}

	UFUNCTION(NotBlueprintCallable)
	void RequestAnimation(EFeatureTagMedallionHydra Tag, EFeatureSubTagMedallionHydra SubTag, float AnimationDuration = -1.0)
	{
		if (MedallionHydra == nullptr || MedallionHydra.LocomotionFeature == nullptr)
			return;

		float DesiredPlayrate = 1.0;
		if (AnimationDuration > KINDA_SMALL_NUMBER)
		{
			float AnimSequenceLength = GetAnimationLength(Tag, SubTag);
			if (AnimSequenceLength < KINDA_SMALL_NUMBER)
				CurrentAnimationDuration = AnimationDuration;
			else
			{
				DesiredPlayrate = AnimSequenceLength / AnimationDuration;
				CurrentAnimationDuration = AnimationDuration;
			}
		}
		else
		{
			float AnimSequenceLength = GetAnimationLength(Tag, SubTag);
			if (AnimSequenceLength < KINDA_SMALL_NUMBER)
				CurrentAnimationDuration = 1.0;
			else
				CurrentAnimationDuration = AnimSequenceLength;
		}

		if (CurrentAnimationRequest.Tag != Tag || CurrentAnimationRequest.SubTag != SubTag)
		{
			{
				FSanctuaryBossMedallionHydraEventAnimationData Data;
				Data.Tag = Tag;
				Data.SubTag = SubTag;
				Data.CustomPlayRate = DesiredPlayrate;
				USanctuaryBossMedallionHydraEventHandler::Trigger_OnRequestedAnimationChanged(MedallionHydra, Data);
			}
			{
				FSanctuaryBossMedallionManagerEventAnimationData Data;
				Data.Tag = Tag;
				Data.SubTag = SubTag;
				Data.CustomPlayRate = DesiredPlayrate;
				Data.Hydra = MedallionHydra;
				UMedallionHydraAttackManagerEventHandler::Trigger_OnRequestedAnimationChanged(RefsComp.Refs.HydraAttackManager, Data);
			}
		}

		CurrentAnimationRequest.Tag = Tag;
		CurrentAnimationRequest.SubTag = SubTag;
		CurrentAnimationRequest.CustomPlayRate = DesiredPlayrate;
	}

	float GetAnimationLength(EFeatureTagMedallionHydra Tag, EFeatureSubTagMedallionHydra SubTag)
	{
		FLocomotionFeatureBossMedallionHydraAnimData Data = MedallionHydra.LocomotionFeature.MedallionAnimData;
		if (Tag == EFeatureTagMedallionHydra::None_Idling)
			return Data.Mh.HighestProbabilityAnimation.SequenceLength;
		if (Tag == EFeatureTagMedallionHydra::Submerge)
			return Data.Submerge.Sequence.SequenceLength;
		if (Tag == EFeatureTagMedallionHydra::Emerge)
			return Data.Emerge.Sequence.SequenceLength;
		if (Tag == EFeatureTagMedallionHydra::Death)
			return Data.Death.Sequence.SequenceLength;
		if (Tag == EFeatureTagMedallionHydra::StrangleStruggle)
			return Data.StrangleStruggle.BlendSpace.PlayLength;

		if (Tag == EFeatureTagMedallionHydra::Cheerlead)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.CheerleadStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh || SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.CheerleadMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.CheerleadEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::BiteUnder)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.BiteUnderStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.BiteUnderMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.BiteUnderEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::Bite)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.BiteStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.BiteMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.BiteEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::WaveAttack)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.WaveAttackStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.WaveAttackAction.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.WaveAttackEnd.Sequence.SequenceLength;
		}
		
		if (Tag == EFeatureTagMedallionHydra::RainAttack)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.RainAttackAction.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::ProjectileSingle)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.ProjectileSingleAction.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::ProjectileFlying)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.ProjectileFlyingAction.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::ProjectileTripple)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.ProjectileTrippleAction.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::MachineGun)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.MachineGunStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.MachineGunAction.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.MachineGunEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::LaserOver)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.LaserOverStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.LaserOverActionMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.LaserOverEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::LaserForward)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.LaserForwardStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.LaserForwardAction.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.LaserForwardEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::Roar)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.RoarStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.RoarMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.RoarEnd.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::BallistaAggro)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Start)
				return Data.BallistaAggroStart.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::Mh)
				return Data.BallistaAggroMh.Sequence.SequenceLength;
			if (SubTag == EFeatureSubTagMedallionHydra::End)
				return Data.BallistaAggroEnd.Sequence.SequenceLength;
		}
		if (Tag == EFeatureTagMedallionHydra::BallistaAggroCanceled)
			return Data.BallistaAggroCanceled.Sequence.SequenceLength;
		if (Tag == EFeatureTagMedallionHydra::BallistaAggroDeath)
			return Data.BallistaAggroDeath.Sequence.SequenceLength;

		if (Tag == EFeatureTagMedallionHydra::MeteorSpawn)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.MeteorSpawn.Sequence.SequenceLength;
		}

		if (Tag == EFeatureTagMedallionHydra::MeteorFire)
		{
			if (SubTag == EFeatureSubTagMedallionHydra::Action)
				return Data.MeteorFire.Sequence.SequenceLength;
		}

		devCheck(false, "Please add support for " + Tag + " / " + SubTag + " in SanctuaryBossMedallionHydraAnimComponent.as to fetch correct animation length");
		return Data.Mh.HighestProbabilityAnimation.SequenceLength;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CachedMio != nullptr && CachedZoe != nullptr)
		{
			float MioProgress = CachedMio.GetButtonMashProgress(MedallionTags::MedallionGloryKillButtonmashInstigator);
			float ZoeProgress = CachedZoe.GetButtonMashProgress(MedallionTags::MedallionGloryKillButtonmashInstigator);
			CachedMioZoeStrangleAlpha = (MioProgress + ZoeProgress) * 0.5;
		}
	}
};