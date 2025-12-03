class UMultiShotAnimationActorDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AMultiShotAnimationActor;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideProperty(n"InitialIdleAnimation.bLoop");
		HideProperty(n"InitialIdleAnimation.BlendType");
		HideProperty(n"InitialIdleAnimation.BlendTime");
		HideProperty(n"InitialIdleAnimation.BlendOutTime");
		HideProperty(n"InitialIdleAnimation.bPauseAtEnd");

		auto AnimationActor = Cast<AMultiShotAnimationActor>(GetCustomizedObject());
		if(AnimationActor == nullptr)
			return;

		AnimationActor.InitialIdleAnimation.bLoop = true;
	}
}

class AMultiShotAnimationActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditAnywhere)
	UClass CharacterABP;

	FHazeAnimationDelegate OnBlendingOut;

	/* if null the actor will be hidden when the game starts, otherwise this animation will be played */
	UPROPERTY(EditInstanceOnly)
	FHazePlaySlotAnimationParams InitialIdleAnimation;
	default InitialIdleAnimation.bLoop = true;

	UPROPERTY(EditInstanceOnly)
	TArray<FMultiShotAnimationTriggerSequence> AnimationTriggerSequences;

	int CurrentAnimationSequenceIndex = -1;
	int CurrentAnimationIndex = -1;

	int QueuedSequenceIndex = -1;

	bool bIgnoreBlendingOut = false;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(CharacterABP == nullptr)
		{
			CharacterABP = Cast<UClass>(LoadObject(nullptr, "/Game/Animation/Blueprints/ABP/ABP_Character_Simple.ABP_Character_Simple_C"));
		}

		if(SkelMesh.SkeletalMeshAsset == nullptr)
		{
			SkelMesh.SetSkeletalMeshAsset(Cast<USkeletalMesh>(LoadObject(nullptr, "/Game/Characters/Generic/BaseMale/BaseMale.BaseMale")));
			SkelMesh.EditorOnlyOverrideAnimationData(nullptr);
		}

		if(SkelMesh.SkeletalMeshAsset == nullptr)
			return;

		SkelMesh.ResetAllAnimation();

		if(InitialIdleAnimation.Animation == nullptr && (AnimationTriggerSequences.Num() == 0 || AnimationTriggerSequences[0].Animations.Num() == 0 || AnimationTriggerSequences[0].Animations[0].Animation == nullptr))
		{
			SkelMesh.SetAnimClass(CharacterABP);
			return;
		}

		if(InitialIdleAnimation.Animation != nullptr)
			SkelMesh.EditorOnlyOverrideAnimationData(InitialIdleAnimation.Animation);
		else
			SkelMesh.EditorOnlyOverrideAnimationData(AnimationTriggerSequences[0].Animations[0].Animation);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SkelMesh.SetAnimClass(CharacterABP);
		OnBlendingOut.BindUFunction(this, n"HandleBlendingOut");

		if(InitialIdleAnimation.Animation == nullptr)
		{
			SetActorHiddenInGame(true);
		}
		else
		{
			SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut, InitialIdleAnimation);
		}

		BindTriggers();
	}

	void BindTriggers()
	{
		for(int i = 0; i < AnimationTriggerSequences.Num(); i++)
		{
			if(AnimationTriggerSequences[i].Trigger == nullptr)
				continue;

			AnimationTriggerSequences[i].Trigger.OnPlayerEnterMultiShotTrigger.AddUFunction(this, n"OnPlayerEnter");
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player, AMultiShotAnimationPlayerTrigger Trigger)
	{
		int IndexOfTrigger = -1;
		for(int i = 0; i < AnimationTriggerSequences.Num(); i++)
		{
			if(AnimationTriggerSequences[i].Trigger == Trigger)
			{
				IndexOfTrigger = i;
				break;
			}
		}
		devCheck(IndexOfTrigger != -1, "IndexOfTrigger was still -1, this shouldn't happen");

		AnimationTriggerSequences[IndexOfTrigger].Trigger.OnPlayerEnterMultiShotTrigger.Unbind(this, n"OnPlayerEnter");

		TriggerSequenceAtIndex(IndexOfTrigger);
	}

	UFUNCTION()
	void TriggerSequenceAtIndex(int Index)
	{
		devCheck(Index >= 0 && Index < AnimationTriggerSequences.Num(), "Tried to trigger sequence at an index that was out of range");

		// Current animation is earlier than queued sequence index or current sequence index so we just return
		if(CurrentAnimationSequenceIndex >= Index || QueuedSequenceIndex >= Index)
			return;

		if(!IsCurrentAnimationInterruptible())
		{
			// Queue up animation since current animation is not interruptible
			QueuedSequenceIndex = Index;
			return;
		}

		SetActorHiddenInGame(false);

		CurrentAnimationSequenceIndex = Index;
		CurrentAnimationIndex = 0;

		bIgnoreBlendingOut = true;
		StartAnimation();
		bIgnoreBlendingOut = false;
	}

	UFUNCTION()
	private void HandleBlendingOut()
	{
		if(bIgnoreBlendingOut)
			return;

		if(CurrentAnimationSequenceIndex == -1)
		{
			SetActorHiddenInGame(true);
			return;
		}

		int NewAnimationIndex = CurrentAnimationIndex + 1;
		FMultiShotAnimationTriggerSequence Current = AnimationTriggerSequences[CurrentAnimationSequenceIndex];

		// There is a pending queue, check if next animation is interruptible or if it just ended
		if(QueuedSequenceIndex >= 0 && (NewAnimationIndex >= Current.Animations.Num() || IsAnimationInterruptible(CurrentAnimationSequenceIndex, NewAnimationIndex)))
		{
			CurrentAnimationSequenceIndex = QueuedSequenceIndex;
			QueuedSequenceIndex = -1;
			CurrentAnimationIndex = 0;
			StartAnimation();
			return;
		}

		if(NewAnimationIndex >= Current.Animations.Num())
		{
			SetActorHiddenInGame(true);
			CurrentAnimationIndex = NewAnimationIndex;
			return;
		}

		CurrentAnimationIndex = NewAnimationIndex;
		StartAnimation();
	}

	void StartAnimation()
	{
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), OnBlendingOut, AnimationTriggerSequences[CurrentAnimationSequenceIndex].Animations[CurrentAnimationIndex]);
	}

	bool IsCurrentAnimationInterruptible() const
	{
		return IsAnimationInterruptible(CurrentAnimationSequenceIndex, CurrentAnimationIndex);
	}

	bool IsAnimationInterruptible(int SequenceIndex, int AnimationIndex) const
	{
		// We aren't playing an animation, so yes, it's interruptible
		if(SequenceIndex == -1)
			return true;

		FMultiShotAnimationTriggerSequence Current = AnimationTriggerSequences[SequenceIndex];

		// Animation is over so it is interruptible!
		if(AnimationIndex >= Current.Animations.Num())
			return true;

		if(Current.bAllowInterrupting || Current.Animations[AnimationIndex].bLoop)
			return true;

		return false;
	}
}

struct FMultiShotAnimationTriggerSequence
{
	UPROPERTY()
	AMultiShotAnimationPlayerTrigger Trigger;

	UPROPERTY()
	TArray<FHazePlaySlotAnimationParams> Animations;

	/* If true, the next animation sequence can start before a looping animation is reached (if we're in a looping animation we can always interrupt) */
	UPROPERTY()
	bool bAllowInterrupting = false;
}