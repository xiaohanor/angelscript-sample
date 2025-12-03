
UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/SlideIconBillboardGradient.SlideIconBillboardGradient", EditorSpriteOffset="X=0 Y=0 Z=75"))
class UGrappleSlidePointComponent : UGrapplePointBaseComponent
{
	default TargetableCategory = n"ContextualMoves";
	default GrappleType = EGrapplePointVariations::SlidePoint;
	default UsableByPlayers = EHazeSelectPlayer::Both;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchVelocity = 2500.0;

	UPROPERTY(BlueprintReadOnly)
	bool bUsePreferedDirection = false;

	/*
	 * This is how far infront of the point we should align with the points forward direction to clear eventual ledges/etc
	 * Setting this will enforce a minimum activation range on the point relative to the value you set
	 */
	UPROPERTY(EditInstanceOnly, Category = "Settings", AdvancedDisplay)
	float OverrideEdgeClearanceValue = 0;

	/*
	 * Launch direction for player as long as they are inside the assigned acceptance range
	 * Length of vector is irrelevant as it will be normalised upon use
	 * > 0 to enable use / visualization
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector PreferedDirection;

	/*
	 * Should the prefered direction be locked in once grapple slide starts
	 * - False = If point moves/rotates during grapple slide then direction will update throughout the move 
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bLockDirectionOnActivation = true;

	/*
	 * Whether the resulting slide should be forced in the preferred direction instead of freeform.
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bForceSlideInPreferredDirection = false;

	/*
	 *	Entry Angle range for direction assistance to kick in 
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUsePreferedDirection", EditConditionHides), Category = "Settings")
	float AcceptanceDegrees = 30.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		
		bUsePreferedDirection = PreferedDirection.IsNearlyZero() ? false : true;

		if(OverrideEdgeClearanceValue > 0)
			MinimumRange = OverrideEdgeClearanceValue + 250;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

#if EDITOR
	void AlignWithGround()
	{
		FHazeTraceSettings GroundTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		GroundTrace.UseLine();

		FHitResult GroundHit = GroundTrace.QueryTraceSingle(WorldLocation, WorldLocation + (FVector::UpVector * -1000));

		if (!GroundHit.bStartPenetrating && GroundHit.bBlockingHit)
		{
			FVector Targetlocation = GroundHit.ImpactPoint;
			Targetlocation += GroundHit.ImpactNormal * 5;

			FVector Forward = Owner.ActorRelativeRotation.ForwardVector.ConstrainToPlane(GroundHit.ImpactNormal).GetSafeNormal();
			FRotator TargetRotation = FRotator::MakeFromZX(GroundHit.ImpactNormal, Forward);

			Owner.SetActorLocationAndRotation(Targetlocation, TargetRotation);

			//Toggle actor selection just to update transform widgets
			TArray<AActor> SelectedActors = Editor::SelectedActors;
			Editor::SelectActor(nullptr);
			Editor::SelectActors(SelectedActors);
		}
	}
#endif
}

#if EDITOR

class UGrappleSlidePointCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AGrappleSlidePoint;

	UHazeImmediateDrawer Drawer;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		if(GetCustomizedObject().World != nullptr)
		{
			Drawer = AddImmediateRow(n"Functions");
		}
		else
			HideCategory(n"AlignWithGround");

		EditCategory(n"Functions", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Settings", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Visuals", CategoryType = EScriptDetailCategoryType::Important);
		EditCategory(n"Targetable", CategoryType = EScriptDetailCategoryType::Important);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(GetCustomizedObject().World == nullptr)
			return;

		if(!Drawer.IsVisible())
			return;

		auto Section = Drawer.Begin();

		FHazeImmediateButtonHandle Button = Section.Button("Align With Ground");

		// If Button was clicked
		if(Button)
		{
			if(ObjectsBeingCustomized.Num() > 1)
				Section.Text("Multiple Actors Selected").Color(FLinearColor::Gray).Bold();

			for (UObject Object : ObjectsBeingCustomized)
			{
				AActor ActorCheck = Cast<AActor>(Object);

				if(ActorCheck == nullptr)
					continue;

				UGrappleSlidePointComponent SlideComp = UGrappleSlidePointComponent::Get(ActorCheck);

				if(SlideComp == nullptr)
					continue;

				SlideComp.AlignWithGround();
			}
		}

		Drawer.End();
	}
}
#endif