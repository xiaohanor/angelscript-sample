UCLASS(Abstract)
class AGrappleHook : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeTEMPCableComponent Cable;
	default Cable.bSkipCableUpdateWhenNotVisible = true;

	UPROPERTY(DefaultComponent, Attach = Cable)
	USceneComponent HookRoot;

	UPROPERTY(DefaultComponent, Attach = HookRoot)
	UStaticMeshComponent HookMesh;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance MAT_Scifi;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance MAT_Fantasy;

	AHazePlayerCharacter UsingPlayer;
	
	float Tense = 0.95;
	bool bCableAttached = false;
	bool bWasHidden = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void CheckMaterial()
	{
		UPlayerVariantComponent VariantComp = UPlayerVariantComponent::GetOrCreate(UsingPlayer);
		switch(VariantComp.GetPlayerVariantType())
		{
			case(EHazePlayerVariantType::Scifi):
				Cable.SetMaterial(0, MAT_Scifi);
				break;
			
			case(EHazePlayerVariantType::Fantasy):
				Cable.SetMaterial(0, MAT_Fantasy);
				break;

			default:
				Cable.SetMaterial(0, MAT_Scifi);
				break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (IsHidden())
		{
			bWasHidden = true;
			return;
		}

		if (bWasHidden)
		{
			bWasHidden = false;
			Cable.TeleportCable(UsingPlayer.Mesh.GetSocketLocation(n"LeftAttach"));
		}

		FVector Direction = UsingPlayer.Mesh.GetSocketLocation(n"LeftAttach") - ActorLocation;
		float DistToTarget = Math::Max(Direction.Size(), 1.0);
		float Length = DistToTarget * Tense;
		Cable.CableLength = Length;

		if(UsingPlayer == nullptr || bCableAttached)
			return;

		Cable.SetAttachEndToComponent(UsingPlayer.Mesh, n"LeftAttach");
		bCableAttached = true;
	}
}