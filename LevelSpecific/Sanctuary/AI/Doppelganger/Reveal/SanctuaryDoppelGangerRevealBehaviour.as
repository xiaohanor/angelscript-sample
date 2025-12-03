class USanctuaryDoppelGangerRevealBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Animation); 

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	UHazeSkeletalMeshComponentBase Mesh;
	bool bRevealed = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		
		DoppelComp.TrueForm = Mesh.SkeletalMeshAsset;
		DoppelComp.TrueMaterials = Mesh.Materials;
		
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		Reset();
	}

	void Reset()
	{
		bRevealed = false;

		TArray<UDoppelgangerTrueFormStaticMeshComponent> TrueFormMeshes;
		Owner.GetComponentsByClass(TrueFormMeshes);
		for (UDoppelgangerTrueFormStaticMeshComponent TrueFormMesh : TrueFormMeshes)
		{
			TrueFormMesh.SetVisibility(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bRevealed)
			return false;
		if(DoppelComp.MimicState != EDoppelgangerMimicState::Reveal)
			return false;
		if (DoppelComp.MimicTarget == nullptr )
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > DoppelSettings.RevealDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Mesh.SetSkeletalMeshAsset(DoppelComp.TrueForm);
		for (int i = 0; i < DoppelComp.TrueMaterials.Num(); i++)
		{
			Mesh.SetMaterial(i, DoppelComp.TrueMaterials[i]);
		}

		DoppelComp.MimicTarget = nullptr;
		USanctuaryDoppelgangerEventHandler::Trigger_Reveal(Owner);
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerReveal, EBasicBehaviourPriority::High, this, DoppelSettings.RevealDuration);

		TArray<UDoppelgangerTrueFormStaticMeshComponent> TrueFormMeshes;
		Owner.GetComponentsByClass(TrueFormMeshes);
		for (UDoppelgangerTrueFormStaticMeshComponent TrueFormMesh : TrueFormMeshes)
		{
			TrueFormMesh.SetVisibility(true);
		}
	}
}

class UDoppelgangerTrueFormStaticMeshComponent : UStaticMeshComponent
{
	default bCanEverAffectNavigation = false;
	default CollisionProfileName = n"NoCollision";
}

