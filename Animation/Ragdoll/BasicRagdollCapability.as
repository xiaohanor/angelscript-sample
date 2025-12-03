// Simple ragdoll capability, use for simple actors or as base for more specific 
// capabilities or where ragdoll is used as a part of ai death capabilities etc.
class UBasicRagdollCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Ragdoll");

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	URagdollComponent RagdollComp;	
	UHazeSkeletalMeshComponentBase Mesh;
	UHazeCapsuleCollisionComponent Collision;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RagdollComp = URagdollComponent::GetOrCreate(Owner);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");

		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		if (CharOwner != nullptr)
		{
			Mesh = CharOwner.Mesh;
			Collision = CharOwner.CapsuleComponent;
		}
		else
		{
			Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
			Collision = UHazeCapsuleCollisionComponent::Get(Owner);
		}
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		RagdollComp.ClearRagdoll(Mesh, Collision);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!RagdollComp.IsRagdollAllowed())
			return false;
		if (Mesh == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Never recover from ragdoll
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);

		RagdollComp.ApplyRagdoll(Mesh, Collision);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);

		RagdollComp.ClearRagdoll(Mesh, Collision);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: Simulation should stop when ragdoll has mostly settled, verify that this happens!
	}
};