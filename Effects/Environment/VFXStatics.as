
UFUNCTION(Category = "VFX")
mixin AHazeActor FindRelevantAttachActorForNiagara(AHazePlayerCharacter Player)
{
	auto RelevantMesh = Player.FindRelevantAttachMeshForNiagara();
	if(RelevantMesh != nullptr)
		return Cast<AHazeActor>(RelevantMesh.Owner);
	return nullptr;
}

UFUNCTION(Category = "VFX")
mixin UHazeSkeletalMeshComponentBase FindRelevantAttachMeshForNiagara(AHazePlayerCharacter Player)
{
	// Check for explicit overrides
	auto SettingsComp = UPlayerVFXSettingsComponent::Get(Player);
	if (SettingsComp != nullptr && SettingsComp.RelevantAttachMesh.Get() != nullptr)
		return SettingsComp.RelevantAttachMesh.Get();

	// check for mounts first	
	auto AttachParent = Player.GetAttachParentActor();
	if(AttachParent != nullptr)
	{
		TArray<UHazeSkeletalMeshComponentBase> AttachParentMeshes;
		AttachParent.GetComponentsByClass(UHazeSkeletalMeshComponentBase, AttachParentMeshes);

		for(auto IterAttachParentMesh : AttachParentMeshes)
		{
			if (IterAttachParentMesh.HasTag(n"NotRelevantForVFX"))
				continue;
			if(!IterAttachParentMesh.IsHiddenInGame())
			{
				return IterAttachParentMesh;
			}
		}
	}

	// check on the player
	TArray<UHazeSkeletalMeshComponentBase> PlayerMeshes;
	Player.GetComponentsByClass(UHazeSkeletalMeshComponentBase, PlayerMeshes);
	for(auto IterPlayerMesh : PlayerMeshes)
	{
		if (IterPlayerMesh.HasTag(n"NotRelevantForVFX"))
			continue;
		if(!IterPlayerMesh.IsHiddenInGame())
		{
			//Print(f"{IterPlayerMesh=}");
			return IterPlayerMesh;
		}
	}

	// if player is hidden then we probably have an actor on the player that is visible
	TArray<AActor> AttachedActors;
	Player.GetAttachedActors(AttachedActors, false, true);

	for(auto IterAttachedActor : AttachedActors)
	{
		// ignore other player
		if(Player.OtherPlayer == IterAttachedActor)
		{
			continue;
		}

		// Ignore actors that are owned by the other player
		if(IterAttachedActor.AttachParentActor != nullptr && Player.OtherPlayer == IterAttachedActor.AttachParentActor)
			continue;

		TArray<UHazeSkeletalMeshComponentBase> AttachedActorMeshes;
		IterAttachedActor.GetComponentsByClass(UHazeSkeletalMeshComponentBase, AttachedActorMeshes);

		// no meshes
		if(AttachedActorMeshes.Num() <= 0)
			continue;

		for(auto IterAttachedActorMesh : AttachedActorMeshes)
		{
			if (IterAttachedActorMesh.HasTag(n"NotRelevantForVFX"))
				continue;
			// the recently rendered check here is a hack to workaround the problem that the mesh becomes hidden, 
			// due to being disabled, before the actor gets fully disabled. So we can't check for IsDisabled().
			// @TODO: check if this is intentional by the disabled system. Another fix would be to put a death effect
			// on the shapeshiffing actors instead. 
			if(!IterAttachedActorMesh.IsHiddenInGame() || IterAttachedActorMesh.WasRecentlyRendered(0.2))
			{
				return IterAttachedActorMesh;
			}
		}
	}

	return Player.Mesh;
}

/* Deactivates the effect immediately in contrast to Deactivate() which might allow the particles to 
live out there full lifetime before the emitter is killed */
UFUNCTION(Category = "VFX")
mixin void DeactivateImmediately(UNiagaraComponent NiagaraComponent)
{
	/** 
		DeactiveImmediate() isn't exposed to BP via c++ bindings,
		because of reasons, so we do it here instead  */
	if (IsValid(NiagaraComponent))
		NiagaraComponent.DeactivateImmediate();
}

namespace Niagara
{
	UFUNCTION(Category = "Niagara", Meta = (AdvancedDisplay = "AttachSocket"))
	UNiagaraComponent SpawnOneShotNiagaraSystemAttachedAtLocation(UNiagaraSystem NiagaraSystem, USceneComponent AttachToComponent, FVector WorldLocation, FName AttachSocket = NAME_None) 
	{
		UNiagaraComponent EffectComp = Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem, WorldLocation);
		if (AttachToComponent != nullptr && EffectComp != nullptr)
			EffectComp.AttachToComponent(AttachToComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		return EffectComp;
	}

	UFUNCTION(Category = "Niagara", Meta = (AdvancedDisplay = "AttachSocket"))
	UNiagaraComponent SpawnOneShotNiagaraSystemAttachedWithRelativeTransform(UNiagaraSystem NiagaraSystem, USceneComponent AttachToComponent, FTransform RelativeTransform, FName AttachSocket = NAME_None) 
	{
		FTransform ParentTransform;
		if (AttachToComponent != nullptr)
			ParentTransform = AttachToComponent.WorldTransform;

		UNiagaraComponent EffectComp = Niagara::SpawnOneShotNiagaraSystemAtLocation(NiagaraSystem,
			ParentTransform.TransformPosition(RelativeTransform.Location),
			ParentTransform.TransformRotation(RelativeTransform.Rotator()));

		if (AttachToComponent != nullptr && EffectComp != nullptr)
			EffectComp.AttachToComponent(AttachToComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		return EffectComp;

	}

	// Aboslute means "fixed" or static; meaning that the niagara component will not inherit the movement or scale of the owner, when that owner moves or scales. 
	UFUNCTION(Category = "Niagara", Meta = (AdvancedDisplay = "AttachSocket, bAbsoluteLocation, bAbsoluteRotation, bAbsoluteScale"))
	UNiagaraComponent SpawnLoopingNiagaraSystemAttachedAtLocation(
		UNiagaraSystem NiagaraSystem,
		 USceneComponent AttachToComponent,
		  FVector WorldLocation, 
		  FName AttachSocket = NAME_None,
		   bool bAbsoluteLocation = false,
		     bool bAbsoluteRotation = false,
			   bool bAbsoluteScale = false) 
	{
		UNiagaraComponent EffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(NiagaraSystem, AttachToComponent, AttachSocket);
		EffectComp.SetAbsolute(bAbsoluteLocation, bAbsoluteRotation, bAbsoluteScale);
		EffectComp.SetWorldLocation(WorldLocation);
		return EffectComp;
	}
}

class UPlayerVFXSettingsComponent : UActorComponent
{
	TInstigated<UHazeSkeletalMeshComponentBase> RelevantAttachMesh;
	TInstigated<USceneComponent> RelevantAttachRoot;
}

namespace VFX
{

UFUNCTION(Category = "VFX")
TArray<UMeshComponent> FindAllRelevantPlayerMeshes(AHazePlayerCharacter Player)
{
	TArray<UMeshComponent> RelevantMeshes;
	TArray<UMeshComponent> AttachedMeshes;

	// Check for explicit overrides
	auto SettingsComp = UPlayerVFXSettingsComponent::Get(Player);
	if (SettingsComp != nullptr && SettingsComp.RelevantAttachRoot.Get() != nullptr)
	{
		USceneComponent AttachRoot = SettingsComp.RelevantAttachRoot.Get();
		AttachRoot.GetChildrenComponentsByClass(UMeshComponent, true, AttachedMeshes);

		UMeshComponent AttachRootMesh = Cast<UMeshComponent>(AttachRoot);
		if (AttachRootMesh != nullptr)
			RelevantMeshes.Add(AttachRootMesh);
	}
	else
	{
		UMeshComponent BaseMesh = Player.FindRelevantAttachMeshForNiagara();
		RelevantMeshes.Add(BaseMesh);

		BaseMesh.GetChildrenComponentsByClass(UMeshComponent, true, AttachedMeshes);
	}

	for (UMeshComponent MeshComp : AttachedMeshes)
	{
		if (MeshComp.IsHiddenInGame() || !MeshComp.IsVisible() || MeshComp.Owner.IsHidden())
			continue;
		if (!MeshComp.bRenderInMainPass)
			continue;
		if (MeshComp.HasTag(n"NotRelevantForVFX"))
			continue;

		// Ignore meshes that only have translucent or additive materials (this will be stuff like haze spheres)
		bool bAnyValidMaterials = false;
		for (int i = 0, Count = MeshComp.NumMaterials; i < Count; ++i)
		{
			UMaterialInterface Material = MeshComp.GetMaterial(i);
			if (Material == nullptr)
				continue;
			EBlendMode BlendMode = Material.GetBlendMode();
			if (BlendMode == EBlendMode::BLEND_Translucent)
				continue;
			if (BlendMode == EBlendMode::BLEND_Additive)
				continue;

			bAnyValidMaterials = true;
			break;
		}

		if (bAnyValidMaterials)
			RelevantMeshes.Add(MeshComp);
	}
	
	return RelevantMeshes;
}
}