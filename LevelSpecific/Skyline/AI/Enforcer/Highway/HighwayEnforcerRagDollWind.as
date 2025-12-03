class AHighwayEnforcerRagDollWind : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	
	UPROPERTY(EditAnywhere)
	float WindForce = 5000;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "WindManager";
	default Billboard.WorldScale3D = FVector(1);
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UHazeTeam AiTeam = HazeTeam::GetTeam(AITeams::Default);
		if (AiTeam == nullptr)
			return;

		for (AHazeActor Member : AiTeam.GetMembers())
		{
			if (Member == nullptr)
				continue;
			auto RagdollComp = URagdollComponent::Get(Member);
			if(RagdollComp != nullptr && RagdollComp.IsRagdollAllowed())
			{
				UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Member);
				RagdollComp.ApplyRagdollImpulse(Mesh, FRagdollImpulse(ERagdollImpulseType::WorldSpace, ActorForwardVector * WindForce * DeltaSeconds, Mesh.GetSocketLocation(n"Hips"), n"Hips"));
			}
		}
	}
};