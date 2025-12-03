enum ERagdollImpulseType
{
	WorldSpace,
	ActorSpace,
	MeshSpace,
}

struct FRagdollImpulse
{
	UPROPERTY()
	ERagdollImpulseType Type = ERagdollImpulseType::WorldSpace;

	UPROPERTY()
	FVector Force;

	UPROPERTY()
	FVector Origin;	

	UPROPERTY()
	FName Bone;	

	FRagdollImpulse(ERagdollImpulseType _Type, FVector _Force, FVector _Origin, FName _Bone = NAME_None)
	{
		Type = _Type;
		Force = _Force;
		Origin = _Origin;
		Bone = _Bone;
	}

	FRagdollImpulse GetWorldSpaceImpulse(UHazeSkeletalMeshComponentBase Mesh) const
	{
		FRagdollImpulse WorldImpulse = this;
		WorldImpulse.Type = ERagdollImpulseType::WorldSpace;

		if (ensure((Mesh != nullptr) && (Mesh.Owner != nullptr)))
		{
			FTransform Transform = FTransform::Identity;
			if (this.Type == ERagdollImpulseType::ActorSpace)
				Transform = Mesh.Owner.ActorTransform;
			else if (this.Type == ERagdollImpulseType::MeshSpace)
				Transform = Mesh.WorldTransform;

			WorldImpulse.Force = Transform.TransformVector(this.Force);
			WorldImpulse.Origin = Transform.TransformPosition(this.Origin);
		}

		return WorldImpulse;
	}

	bool IsValid() const
	{
		return !Force.IsNearlyZero();
	}
}

struct FRagdollMeshData
{
	FName CollisionProfile = n"NoCollision";
	USceneComponent AttachParent = nullptr;
	FName AttachSocket = NAME_None;
	FTransform RelativeTransform = FTransform::Identity;
}

class URagdollComponent : UActorComponent
{
	TInstigated<bool> bAllowRagdoll;
	default bAllowRagdoll.DefaultValue = false;

	bool bIsRagdolling = false;

	TMap<FInstigator, FRagdollImpulse> PendingImpulses;

	UPROPERTY()
	FVector ImpulseOriginMeshSpace = FVector::ZeroVector;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	FSoundDefReference RagdollSoundDef;

	private TMap<UHazeSkeletalMeshComponentBase, FRagdollMeshData> DefaultMeshData;

	bool IsRagdollAllowed() const
	{
		return bAllowRagdoll.Get();
	}

	UFUNCTION()
	void ApplyRagdoll(UHazeSkeletalMeshComponentBase Mesh, UPrimitiveComponent MovementCollision)
	{
		if (bIsRagdolling)
			return;

		bIsRagdolling = true;

		if (Mesh != nullptr)
		{
			FRagdollMeshData MeshData;
			MeshData.CollisionProfile = Mesh.CollisionProfileName;
			MeshData.AttachParent = Mesh.AttachParent;
			MeshData.AttachSocket = Mesh.AttachSocketName;
			MeshData.RelativeTransform = Mesh.RelativeTransform;
			DefaultMeshData.Add(Mesh, MeshData);

			Mesh.SetSimulateRagdoll(true, n"IgnorePlayerCharacter");

			if(!Mesh.IsCollisionEnabled())
			{
				PrintError(f"Failed to apply Ragdoll to {Mesh}, collision is still disabled after changing the collision profile. Is collision blocked on the mesh or actor?");
			}

			for (auto Slot : PendingImpulses)
			{
				ApplyRagdollImpulse(Mesh, Slot.Value);
			}
		}

		if (MovementCollision != nullptr)
		{
			MovementCollision.AddComponentCollisionBlocker(this);
		}

		if(RagdollSoundDef.SoundDef.IsValid())
			RagdollSoundDef.SpawnSoundDefAttached(Owner, Owner);
	}

	void ApplyRagdollImpulse(UHazeSkeletalMeshComponentBase Mesh, FRagdollImpulse Impulse)
	{
		if (Mesh == nullptr)
			return;
		if (!Impulse.IsValid())
			return;
		FRagdollImpulse WorldImpulse = Impulse.GetWorldSpaceImpulse(Mesh);
		Mesh.AddVelocityChangeImpulseAtLocation(WorldImpulse.Force, WorldImpulse.Origin, WorldImpulse.Bone);		
	}

	void ClearRagdoll(UHazeSkeletalMeshComponentBase Mesh, UPrimitiveComponent MovementCollision)
	{
		if (!bIsRagdolling)
			return;

		bIsRagdolling = false;

		if (Mesh != nullptr)
		{
			Mesh.SetSimulatePhysics(false);
			FRagdollMeshData MeshData;
			DefaultMeshData.Find(Mesh, MeshData);
			Mesh.SetCollisionProfileName(MeshData.CollisionProfile);
			if (MeshData.AttachParent != nullptr)
			{
				Mesh.AttachToComponent(MeshData.AttachParent, MeshData.AttachSocket, EAttachmentRule::SnapToTarget);
				Mesh.RelativeTransform = MeshData.RelativeTransform;
			}
		}		

		if (MovementCollision != nullptr)
		{
			MovementCollision.RemoveComponentCollisionBlocker(this);
		}

		if(RagdollSoundDef.SoundDef.IsValid())
		{
			auto HazeOwner = Cast<AHazeActor>(Owner);
			HazeOwner.RemoveSoundDef(RagdollSoundDef);
		}			
	}
}

