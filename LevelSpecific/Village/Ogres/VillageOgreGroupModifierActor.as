class AVillageOgreGroupModifierActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UVillageOgreGroupModifierComponent ModifierComp;

	UPROPERTY(EditInstanceOnly)
	bool bMakeOgresAngry = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence AngryAnimation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bMakeOgresAngry)
		{
			TListedActors<AVillageOgreBase> Ogres;
			for (AVillageOgreBase Ogre : Ogres.GetArray())
			{
				float DistanceSquared = Math::Square(ModifierComp.Range);
				if (ActorLocation.DistSquared(Ogre.ActorLocation) < DistanceSquared)
					Ogre.PlaySlotAnimation(Animation = AngryAnimation, bLoop = true, StartTime = Math::RandRange(0.0, AngryAnimation.SequenceLength));
			}
		}
	}

	UFUNCTION(CallInEditor)
	void RotateOgres()
	{
	#if EDITOR
		for (AVillageOgreBase Ogre : GetOgresInRange())
		{
			Ogre.SetActorRotation(FRotator(0.0, Math::RandRange(0.0, 360.0), 0.0));
		}
	#endif
	}

	UFUNCTION(CallInEditor)
	void DisableOgreCollision()
	{
	#if EDITOR
		for (AVillageOgreBase Ogre : GetOgresInRange())
		{
			Ogre.CollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	#endif
	}

	UFUNCTION(CallInEditor)
	void ForceLowLod()
	{
		#if EDITOR
		for (AVillageOgreBase Ogre : GetOgresInRange())
		{
			Ogre.SkelMeshComp.SetForcedLOD(4);
		}
	#endif
	}

	#if EDITOR
	TArray<AVillageOgreBase> GetOgresInRange()
	{
		TArray<AVillageOgreBase> Ogres;
		float DistanceSquared = Math::Square(ModifierComp.Range);

		auto Actors = Editor::GetAllEditorWorldActorsOfClass(AVillageOgreBase);
		for (auto It : Actors)
		{
			AVillageOgreBase Ogre = Cast<AVillageOgreBase>(It);
			if (ActorLocation.DistSquared(Ogre.ActorLocation) < DistanceSquared)
				Ogres.Add(Ogre);
		}

		return Ogres;
	}
	#endif
}

UCLASS(HideCategories = "Tags AssetUserData Collision Cooking Transform Activation Rendering Replication Input Actor LOD Debug")
class UVillageOgreGroupModifierComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	float Range = 5000;
}

class UUVillageOgreGroupModifierComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UVillageOgreGroupModifierComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UVillageOgreGroupModifierComponent GroupModifier = Cast<UVillageOgreGroupModifierComponent>(Component);
		if (GroupModifier != nullptr)
		{
			const float Range = GroupModifier.Range;
			const FVector Origin = GroupModifier.Owner.ActorLocation;

			DrawWireSphere(Origin, Range, FLinearColor::LucBlue, 2);
		}
	}
}