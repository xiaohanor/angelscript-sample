enum EPlayerInheritMovementActivationType
{
	/**
	 * Always active while inside
	 */
	InsideShape,

	/**
	 * Activate while inside and after became grounded
	 */
	InsideShapeAfterGroundImpact,

	/**
	 * Activate while inside and after any physical impact
	 */
	InsideShapeAfterAnyImpact
};

enum EPlayerInheritMovementDeactivationType
{
	/**
	 * Always deactivate while outside.
	 */
	OutsideShape,

	/**
	 * Deactivate while outside and after became grounded.
	 */
	OutsideShapeAfterGroundImpact,

	/**
	 * Deactivate while outside and after any physical impact.
	 */
	OutsideShapeAfterAnyImpact,

	/**
	 * Deactivate if we are outside shape or our movement direction 
	 * is pointing away from the follow component movement direction
	 * and we are airborne.
	 */
	OutsideShapeOrJumpingAway,
};

enum EPlayerInheritMovementFollowType
{
	/**
	 * Follow the inheritMovementComponent
	 */
	FollowInheritComponent,

	/**
	 * Follow whichever mesh we impacted
	 */
	FollowImpactedMesh,

	/**
	 * Follow whichever actor we impacted
	 */
	FollowImpactedActor
};

struct FPlayerInheritMovementInstanceData
{
	bool bIsInsideZone = false;
	bool bFollowActive = false;
	USceneComponent FollowedComp = nullptr;
	FName FollowedSocketName = NAME_None;
};

/**
 * A PlayerTrigger that will make the player follow and un-follow the movement of this component or other contacts.
 */
UCLASS(NotBlueprintable)
class UPlayerInheritMovementComponent : UHazeMovablePlayerTriggerComponent
{	
	access EditAndReadOnly = private, * (editdefaults, readonly);

	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_DuringPhysics;
	default PrimaryComponentTick.bStartWithTickEnabled = true;

	/**
	 * How the player moves to follow this component
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	EMovementFollowComponentType FollowBehavior = EMovementFollowComponentType::ResolveCollision;

	/**
	 * What to follow upon activating inherited movement
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	access:EditAndReadOnly
	EPlayerInheritMovementFollowType FollowType = EPlayerInheritMovementFollowType::FollowInheritComponent; 

	UPROPERTY(EditAnywhere, Category = "Inherit Movement", Meta = (EditCondition = "FollowType == EPlayerInheritMovementFollowType::FollowImpactedMesh"))
	access:EditAndReadOnly
	bool bFollowImpactedMeshSocket = true;

	/**
	 * Do we follow if the followed component moves horizontally? (Along the WorldUp plane)
	 * This will also disable relative position syncing in network.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	access:EditAndReadOnly
	bool bFollowHorizontal = true;

	/**
	 * When to activate the inherited movement.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	access:EditAndReadOnly
	EPlayerInheritMovementActivationType ActivateType = EPlayerInheritMovementActivationType::InsideShapeAfterGroundImpact;

	/**
	 * When to activate the inherited movement.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	access:EditAndReadOnly
	EPlayerInheritMovementDeactivationType DeactivationType = EPlayerInheritMovementDeactivationType::OutsideShapeAfterAnyImpact;

	/**
	 * If true, we will un-follow if the followed component moves down, and we are airborne.
	 * For elevators that move down, turing this off will most likely yield better results.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	access:EditAndReadOnly
	bool bDeactivateIfFollowIsMovingDownWhileAirborne = false;

	/**
	 * Priority of this inherit movement zone compared to others (the floor the player is standing on always has Low priority).
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	EInstigatePriority FollowPriority = EInstigatePriority::Normal;

	/**
	 * How the inherit velocity should be handled when we stop follow this.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement")
	EMovementUnFollowComponentTransferVelocityType UnFollowVelocityType = EMovementUnFollowComponentTransferVelocityType::Release;

	/**
	 * If true, the camera pivot won't lag behind when the follow moves.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement|Camera")
	access:EditAndReadOnly
	bool bCameraInheritsFollowMovement = false;

	/**
	 * Should the camera also inherit the follow movement rotation, making the camera also spin around.
	 */
	UPROPERTY(EditAnywhere, Category = "Inherit Movement|Camera")
	access:EditAndReadOnly
	bool bCameraInheritsFollowMovementRotation = false;

	private TPerPlayer<FPlayerInheritMovementInstanceData> PlayerData;
	private bool bIsAwake = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Disable self and await the trigger events
		bIsAwake = false;
		AddComponentTickBlocker(this);

#if !RELEASE
		ValidateSettings();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnfollowAll();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bAnyPlayerInsideZoneOrFollowing = false;

		for(AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FPlayerInheritMovementInstanceData& Data = PlayerData[Player];
			auto MoveComp = UPlayerMovementComponent::Get(Player);

			if(Data.bIsInsideZone)
			{
				// Enter / Update Inside
				UpdateInsideData(Player, MoveComp);
			}
			else if(!Data.bIsInsideZone && Data.bFollowActive)
			{
				// Update as "outside", meaning we may un-follow, depending on the deactivation settings
				UpdateOutsideData(Player, MoveComp); 
			}

			if(Data.bIsInsideZone || Data.bFollowActive)
			{
				bAnyPlayerInsideZoneOrFollowing = true;
			}
		}

		if(!bAnyPlayerInsideZoneOrFollowing)
		{
			// No players are actively using this component, sleep
			bIsAwake = false;
			AddComponentTickBlocker(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UnfollowAll();
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		if(!bIsAwake)
		{
			bIsAwake = true;
			RemoveComponentTickBlocker(this);
		}

		PlayerData[Player].bIsInsideZone = true;

		if (!PlayerData[Player].bFollowActive)
		{
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			UpdateInsideData(Player, MoveComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		PlayerData[Player].bIsInsideZone = false;

		if (PlayerData[Player].bFollowActive)
		{
			// Update us as "outside", meaning we may un-follow, depending on the deactivation settings
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			UpdateOutsideData(Player, MoveComp);
		}
	}

	protected void UnfollowAll()
	{
		for(auto Player : Game::GetPlayers())
		{
			if(!IsValid(Player))
				continue;
			
			FPlayerInheritMovementInstanceData& Data = PlayerData[Player];

			if(!Data.bFollowActive)
				continue;

			auto MoveComp = UPlayerMovementComponent::Get(Player);
			UnFollowComponent(Data, MoveComp);
		}
	}

	protected void UpdateInsideData(AHazePlayerCharacter Player, UPlayerMovementComponent MoveComp)
	{
		FPlayerInheritMovementInstanceData& Data = PlayerData[Player];

		if(Data.bFollowActive)
		{
			// Even when inside, if we are not following vertical down, un-follow if the followed component moves downwards
			if(ShouldUnFollowFromFollowMovingDown(Data, MoveComp))
			{
				UnFollowComponent(Data, MoveComp);
				return;
			}

			// Even when inside, we may want to un-follow if we start moving away
			if(ShouldUnFollowFromOutsideShapeOrJumpingAway(Data, MoveComp))
			{
				UnFollowComponent(Data, MoveComp);
				return;
			}
		}

		USceneComponent ComponentToFollow = nullptr;
		FName SocketToFollow = NAME_None;
		GetComponentToFollow(MoveComp, ComponentToFollow, SocketToFollow);
		check(ComponentToFollow != nullptr);

		switch(ActivateType)
		{
			case EPlayerInheritMovementActivationType::InsideShape:
			{
				// We are inside the shape, so just start following
				FollowComponent(Data, MoveComp, ComponentToFollow, SocketToFollow);
				return;
			}

			case EPlayerInheritMovementActivationType::InsideShapeAfterGroundImpact:
			{
				// Check if we have ground impact	
				const bool bIsGroundedState = MoveComp.IsOnAnyGround() || MoveComp.HasCustomMovementStatus(n"Perching");
				if(!bIsGroundedState)
					return;

				FollowComponent(Data, MoveComp, ComponentToFollow, SocketToFollow);
				return;
			}

			case EPlayerInheritMovementActivationType::InsideShapeAfterAnyImpact:
			{
				// Check if we have any movement impacts
				const bool bHasImpacts = MoveComp.HasAnyValidBlockingImpacts();
				if(!bHasImpacts)
					return;

				FollowComponent(Data, MoveComp, ComponentToFollow, SocketToFollow);
				return;
			}
		}
	}

	protected void UpdateOutsideData(AHazePlayerCharacter Player, UPlayerMovementComponent MoveComp)
	{
		FPlayerInheritMovementInstanceData& Data = PlayerData[Player];

		if(ShouldUnFollowFromFollowMovingDown(Data, MoveComp))
		{
			UnFollowComponent(Data, MoveComp);
			return;
		}
		
		switch(DeactivationType)
		{
			case EPlayerInheritMovementDeactivationType::OutsideShape:
			{
				// Since we are outside, we simply stop following
				UnFollowComponent(Data, MoveComp);
				return;
			}

			case EPlayerInheritMovementDeactivationType::OutsideShapeAfterGroundImpact:
			{
				const bool bIsGrounded = MoveComp.IsOnAnyGround() || MoveComp.HasCustomMovementStatus(n"Perching");
				if(bIsGrounded)
					UnFollowComponent(Data, MoveComp);

				return;
			}

			case EPlayerInheritMovementDeactivationType::OutsideShapeAfterAnyImpact:
			{
				if(MoveComp.HasAnyValidBlockingContacts())
					UnFollowComponent(Data, MoveComp);

				return;
			}

			case EPlayerInheritMovementDeactivationType::OutsideShapeOrJumpingAway:
			{
				UnFollowComponent(Data, MoveComp);
				return;
			}
		}
	}

	protected void FollowComponent(
		FPlayerInheritMovementInstanceData& Data,
		UPlayerMovementComponent MoveComp,
		USceneComponent ComponentToFollow,
		FName SocketName
	) const
	{
		if(!ensure(IsValid(ComponentToFollow)))
			return;

		if(Data.FollowedComp == ComponentToFollow && Data.FollowedSocketName == SocketName)
		{
			// We are already following this component and socket, no need to update follow
			return;
		}

		if(Data.bFollowActive)
		{
			// Unfollow first, allowing us to add a new follow
			MoveComp.UnFollowComponentMovement(this, UnFollowVelocityType);
		}
		
		Data.bFollowActive = true;
		Data.FollowedComp = ComponentToFollow;
		Data.FollowedSocketName = SocketName;

		MoveComp.FollowComponentMovement(
			ComponentToFollow,
			this,
			FollowBehavior,
			FollowPriority,
			SocketName,
			bFollowHorizontal,
			true,
			true
		);

		if(bCameraInheritsFollowMovement)
			UCameraInheritMovementSettings::SetInheritMovement(MoveComp.HazeOwner, true, this, EHazeSettingsPriority::Gameplay);

		if(bCameraInheritsFollowMovementRotation)
			MoveComp.FollowMovementData.StartApplyMovementRotationToCamera(this);

	}

	protected void UnFollowComponent(
		FPlayerInheritMovementInstanceData& Data,
		UPlayerMovementComponent MoveComp) const
	{
		if(!ensure(Data.bFollowActive))
			return;

		Data.bFollowActive = false;
		Data.FollowedComp = nullptr;
		Data.FollowedSocketName = NAME_None;

		MoveComp.UnFollowComponentMovement(this, UnFollowVelocityType);

		if(bCameraInheritsFollowMovement)
			UCameraInheritMovementSettings::ClearInheritMovement(MoveComp.HazeOwner, this);

		if(bCameraInheritsFollowMovementRotation)
			MoveComp.FollowMovementData.StopApplyMovementRotationToCamera(this);
	}

	void GetComponentToFollow(
		UPlayerMovementComponent MoveComp,
		USceneComponent&out OutComponentToFollow,
		FName&out OutSocketToFollow)
	{
		FMovementHitResult HitToFollow;
		if(!MoveComp.GetAnyValidContact(HitToFollow))
		{
			// If we can't follow the impact, we just follow the component
			// until we get an impact.
			// This might not be what you expect since this will only happen
			// if you have a settings that says follow some kind of impact.
			// But it is also weird not to follow anything if you have the setting
			// follow inside the shape. So for now, this is how its going to be.
			OutComponentToFollow = this;
			OutSocketToFollow = NAME_None;
			return;
		}

		switch(FollowType)
		{
			case EPlayerInheritMovementFollowType::FollowInheritComponent:
			{
				OutComponentToFollow = this;
				OutSocketToFollow = NAME_None;
				return;
			}

			case EPlayerInheritMovementFollowType::FollowImpactedMesh:
			{
				OutComponentToFollow = HitToFollow.Component;

				if(bFollowImpactedMeshSocket)
					OutSocketToFollow = HitToFollow.BoneName;
				else
					OutSocketToFollow = NAME_None;
				return;
			}

			case EPlayerInheritMovementFollowType::FollowImpactedActor:
			{
				OutComponentToFollow = HitToFollow.Component.Owner.RootComponent;
				OutSocketToFollow = NAME_None;
				return;
			}
		}
	}

	/**
	 * If we have disabled following downwards, and the component we are following is moving down, and we are not grounded, stop following it.
	 */
	protected bool ShouldUnFollowFromFollowMovingDown(FPlayerInheritMovementInstanceData& Data, UPlayerMovementComponent MoveComp) const
	{
		if(!Data.bFollowActive)
			return false;

		if(!bDeactivateIfFollowIsMovingDownWhileAirborne)
			return false;

		// Only un-follow while in the air, since we do want to follow down when grounded
		const bool bIsGroundedState = MoveComp.IsOnAnyGround() || MoveComp.HasCustomMovementStatus(n"Perching");
		if(bIsGroundedState)
			return false;

		// Check if the followed component moved downwards along the WorldUp
		const FVector FollowVelocity = MoveComp.GetFollowVelocity();
		if(FollowVelocity.DotProduct(MoveComp.WorldUp) >= 0)
			return false;

		return true;
	}

	protected bool ShouldUnFollowFromOutsideShapeOrJumpingAway(
		FPlayerInheritMovementInstanceData& Data,
		UPlayerMovementComponent MoveComp) const
	{
		if(!Data.bFollowActive)
			return false;

		if(DeactivationType != EPlayerInheritMovementDeactivationType::OutsideShapeOrJumpingAway)
			return false;

		const bool bIsGroundedState = MoveComp.IsOnAnyGround() || MoveComp.HasCustomMovementStatus(n"Perching");
		if(bIsGroundedState)
			return false;

		const FVector FollowVelocity = MoveComp.GetFollowVelocity();
		const FVector MovementVelocity = MoveComp.GetVelocity().ProjectOnTo(FollowVelocity);
		if(MovementVelocity.IsNearlyZero())
			return false;

		if(MovementVelocity.DotProduct(FollowVelocity) > 0)
			return false;

		return true;
	}

#if !RELEASE
	protected void ValidateSettings()
	{
		if(ActivateType == EPlayerInheritMovementActivationType::InsideShape && DeactivationType == EPlayerInheritMovementDeactivationType::OutsideShapeOrJumpingAway)
		{
			PrintError(f"{GetName()} on {Owner.GetActorNameOrLabel()} has invalid settings: ActivateType InsideShape and DeactivationType OutsideShapeOrJumpingAway are not compatible!");
		}
	}
#endif
};