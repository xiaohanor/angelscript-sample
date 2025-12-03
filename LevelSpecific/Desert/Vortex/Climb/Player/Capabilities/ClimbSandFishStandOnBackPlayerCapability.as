struct FClimbSandFishStandOnBackActivateParams
{
	UClimbSandFishFollowComponent FollowComponent;
	USceneComponent ImpactComponent;
	FName ImpactBone;
}

class UClimbSandFishStandOnBackPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	//default CapabilityTags.Add(ArenaSandFish::PlayerTags::ArenaSandFishStandOnBack);

	UClimbSandFishPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;
	UPlayerGrappleComponent GrappleComp;

	FClimbSandFishStandOnBackActivateParams ForceActivationParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);

		VortexSandFish::GetVortexSandFish().ClimbGrapplePoint.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"OnGrappleFinished");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FClimbSandFishStandOnBackActivateParams& Params) const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return false;

		if(MoveComp.HasGroundContact())
		{
			UClimbSandFishFollowComponent FollowComp = UClimbSandFishFollowComponent::Get(MoveComp.GroundContact.Actor);
			if(FollowComp == nullptr)
				return false;

			Params.FollowComponent = FollowComp;
			Params.ImpactComponent = MoveComp.GroundContact.Component;
			Params.ImpactBone = MoveComp.GroundContact.BoneName;

			return true;
		}

		if(ForceActivationParams.FollowComponent != nullptr)
		{
			Params = ForceActivationParams;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return true;

		if(PlayerComp.FollowedSandFishComp == nullptr)
			return true;

		if(PlayerComp.FollowedComponent == nullptr)
			return true;

		if(MoveComp.HasGroundContact())
		{
			UClimbSandFishFollowComponent FollowComp = UClimbSandFishFollowComponent::Get(MoveComp.GroundContact.Actor);
			if(FollowComp == nullptr)
				return true;
		}

		float Distance = 0;
		FindClosestSocket(Distance);
		if(Distance > 5000)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FClimbSandFishStandOnBackActivateParams Params)
	{
		StartFollowing(Params.ImpactComponent, Params.ImpactBone);

		PlayerComp.FollowedSandFishComp = Params.FollowComponent;
		PlayerComp.FollowedComponent = Params.ImpactComponent;
		PlayerComp.FollowedBone = Params.ImpactBone;
		
		PlayerComp.FollowedSandFishComp.PlayersOnBack.AddUnique(Player);

		ForceActivationParams = FClimbSandFishStandOnBackActivateParams();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.FollowedSandFishComp.PlayersOnBack.RemoveSingleSwap(Player);

		MoveComp.UnFollowComponentMovement(this);

		PlayerComp.FollowedSandFishComp = nullptr;
		PlayerComp.FollowedComponent = nullptr;
		PlayerComp.FollowedBone = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasGroundContact())
		{
			StartFollowing(MoveComp.GroundContact.Component, MoveComp.GroundContact.BoneName);
		}
		else
		{
			float Distance = 0;
			const FName ClosestSocket = FindClosestSocket(Distance);
			StartFollowing(PlayerComp.FollowedComponent, ClosestSocket);
		}
	}

	void StartFollowing(USceneComponent Component, FName BoneName) const
	{
		if(PlayerComp.FollowedComponent != nullptr)
		{
			if(Component == PlayerComp.FollowedComponent && BoneName == PlayerComp.FollowedBone)
				return;

			MoveComp.UnFollowComponentMovement(this);
		}

		PlayerComp.FollowedComponent = Component;
		PlayerComp.FollowedBone = BoneName;

		MoveComp.FollowComponentMovement(PlayerComp.FollowedComponent, this, EMovementFollowComponentType::Teleport, EInstigatePriority::High, PlayerComp.FollowedBone);
	}

	FName FindClosestSocket(float& Distance) const
	{
		check(PlayerComp.FollowedSandFishComp != nullptr);

		const USkeletalMeshComponent MeshComp = USkeletalMeshComponent::Get(PlayerComp.FollowedSandFishComp.Owner);
		if(MeshComp != nullptr && MeshComp.bVisible)
		{
			const TArray<FName> Sockets = MeshComp.AllSocketNames;

			FName ClosestSocket = NAME_None;
			float ClosestDistSquared = BIG_NUMBER;
			for(const auto& Socket : Sockets)
			{
				const FVector SocketLocation = MeshComp.GetSocketLocation(Socket);
				const float DistSquared = Player.ActorLocation.DistSquared(SocketLocation);
				if(DistSquared < ClosestDistSquared)
				{
					ClosestDistSquared = DistSquared;
					ClosestSocket = Socket;
				}
			}

			Distance = Math::Sqrt(ClosestDistSquared);
			return ClosestSocket;
		}
		else
		{
			Distance = Player.ActorLocation.Distance(PlayerComp.FollowedSandFishComp.Owner.ActorLocation);
			return NAME_None;
		}
	}

	UFUNCTION()
	private void OnGrappleFinished(AHazePlayerCharacter InPlayer, UGrapplePointBaseComponent InGrapplePoint)
	{
		AVortexSandFish SandFish = VortexSandFish::GetVortexSandFish();
		ForceActivationParams.FollowComponent = UClimbSandFishFollowComponent::Get(SandFish);
		ForceActivationParams.ImpactComponent = SandFish.MeshComp;
		ForceActivationParams.ImpactBone = NAME_None;
	}
};