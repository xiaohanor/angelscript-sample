// Note that the AI must have a default slot animation node in ABP for this to work.
class UAIEntranceAnimationVisibleFixedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;
	UHazeSkeletalMeshComponentBase Mesh;
	UAnimSequence EntranceAnim;
	float EntranceCompleteTime;
	bool bInitialHidden;
	uint InitialHiddenFrame;
	EVisibilityBasedAnimTickOption DefaultVisibilityOption;
	const float AnimationBlendOutTime = 0.3;
	bool bHasEnabledCollision = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn"); // Note that we must do this after e.g. ai animation component resets
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bInitialHidden)
			return;

		// On control side something will handle the entrance the first frame, so we can be visible the next when animation has been run. 
		// On remote we may pass several frames before this happens, so wait for entry to start. 
		if ((HasControl() && (Time::FrameNumber > InitialHiddenFrame + 1)) ||
			EntranceComp.bHasStartedEntry ||
			(Time::FrameNumber > InitialHiddenFrame + 10)) // Safety backup in case entrance is blocked
		{
			Owner.RemoveActorVisualsBlock(this);
			bInitialHidden = false;
		}
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Spawn patterns can set entrance animation, but if we spawn through a scenepoint
		// any animations on these should take precedence
		if (RespawnComp.SpawnParameters.Scenepoint != nullptr)
		{
			UScenepointAnimationComponent ScenepointAnimComp = UScenepointAnimationComponent::Get(RespawnComp.SpawnParameters.Scenepoint.Owner);
			if ((ScenepointAnimComp != nullptr)	&& (ScenepointAnimComp.EntryAnimation != nullptr))
				EntranceComp.EntranceAnim = ScenepointAnimComp.EntryAnimation;
		}

		// Animations will not move the character immediately, so we'll need to hide a few frames
		if(EntranceComp.EntranceAnim != nullptr)
		{
			Owner.AddActorVisualsBlock(this);
			InitialHiddenFrame = Time::FrameNumber;
			bInitialHidden = true;
		}

		// Note that the AI must have a default slot animation node in ABP for this to work.
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBasicAIEntranceAnimData& Data) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(EntranceComp.bHasStartedEntry)
			return false;
		if (EntranceComp.bHasCompletedEntry)
			return false;
		if (EntranceComp.EntranceAnim == nullptr)
			return false;
		Data.Anim = EntranceComp.EntranceAnim;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (Time::GameTimeSeconds > EntranceCompleteTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBasicAIEntranceAnimData Data)
	{
		Super::OnActivated();
		EntranceAnim = Data.Anim;	

		// Consume entrance anim from comp, we never enter twice
		EntranceComp.EntranceAnim = nullptr;

		// Deactivate before end of anim, so we can set blend out time and start behaviours		
		EntranceCompleteTime = Time::GameTimeSeconds + EntranceAnim.PlayLength - AnimationBlendOutTime;

		// Make sure animation plays even if outside of view frustum
		DefaultVisibilityOption = Mesh.VisibilityBasedAnimTickOption;
		Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

		// Note that the AI must have a default slot animation node in ABP for this to work.
		FHazeSlotAnimSettings Params;
		Params.BlendTime = 0.0;
		Owner.PlaySlotAnimation(EntranceAnim, Params);
		Owner.BlockCapabilities(n"Movement", this);

		EntranceComp.bHasStartedEntry = true;
		bHasEnabledCollision = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		// Stop anim regardless of whether we were blocked or complete
		Owner.StopSlotAnimationByAsset(EntranceAnim, 0.3);
		if (!bHasEnabledCollision)
			Owner.UnblockCapabilities(n"Movement", this);
		EntranceComp.bHasCompletedEntry = true;
		Mesh.VisibilityBasedAnimTickOption = DefaultVisibilityOption;
	}

	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (EntranceComp.CollisionDurationAtEndOfEntrance.Get() == 0)
			return;

		if (!bHasEnabledCollision && Time::GameTimeSeconds > EntranceCompleteTime + AnimationBlendOutTime - EntranceComp.CollisionDurationAtEndOfEntrance.Get())
		{			
			Owner.UnblockCapabilities(n"Movement", this);
			bHasEnabledCollision = true;
		}		
	}
}