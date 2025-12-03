namespace ColorDebug
{
	const FLinearColor Black = FLinearColor(0.0, 0.0, 0.0);
	const FLinearColor Charcoal = FLinearColor(0.32, 0.32, 0.32);
	const FLinearColor Gray = FLinearColor(0.5, 0.5, 0.5);
	const FLinearColor Silver = FLinearColor(0.75, 0.75, 0.75);
	const FLinearColor White = FLinearColor(1.0, 1.0, 1.0);

	const FLinearColor Grape = FLinearColor(0.341, 0.058, 0.752);
	const FLinearColor Amethyst = FLinearColor(0.6, 0.231, 0.815);
	const FLinearColor Magenta = FLinearColor(1.0, 0.0, 1.0);
	const FLinearColor Purple = FLinearColor(0.635, 0.380, 0.811);
	const FLinearColor Orchid = FLinearColor(0.85, 0.313, 1.0);
	const FLinearColor Lavender = FLinearColor(0.8, 0.643, 0.878);
	const FLinearColor Bubblegum = FLinearColor(0.917, 0.662, 1.0);

	const FLinearColor Blue = FLinearColor(0.0, 0.0, 1.0);
	const FLinearColor Ultramarine = FLinearColor(0.109, 0.317, 0.905);
	const FLinearColor Lapis = FLinearColor(0.168, 0.517, 1.0);
	const FLinearColor Cornflower = FLinearColor(0.458, 0.658, 1.0);
	const FLinearColor Cerulean = FLinearColor(0.0, 0.705, 0.839);
	const FLinearColor Cyan = FLinearColor(0.0, 1.0, 1.0);
	const FLinearColor Sky = FLinearColor(0.682, 0.784, 1.0);
	const FLinearColor Eggblue = FLinearColor(0.603, 0.917, 0.937);

	const FLinearColor Spruce = FLinearColor(0.545, 0.733, 0.698);
	const FLinearColor Pistachio = FLinearColor(0.886, 1.0, 0.901);
	const FLinearColor Seafoam = FLinearColor(0.698, 0.886, 0.741);
	const FLinearColor Mint = FLinearColor(0.603, 1.0, 0.78);

	const FLinearColor Jade = FLinearColor(0.380, 0.670, 0.537);
	const FLinearColor Algae = FLinearColor(0.592, 0.686, 0.545);
	const FLinearColor Camo = FLinearColor(0.317, 0.407, 0.298);
	const FLinearColor Verdant = FLinearColor(0.13, 0.4, 0.14);
	const FLinearColor Fern = FLinearColor(0.494, 0.807, 0.45);
	const FLinearColor Leaf = FLinearColor(0.647, 0.89, 0.176);
	const FLinearColor Radioactive = FLinearColor(0.776, 1.0, 0.0);
	const FLinearColor Green = FLinearColor(0.0, 1.0, 0.0);

	const FLinearColor Spring = FLinearColor(0.662, 0.658, 0.196);
	const FLinearColor Goldenrod = FLinearColor(0.745, 0.647, 0.364);
	const FLinearColor Flaxen = FLinearColor(0.992, 0.913, 0.682);
	const FLinearColor Grapefruit = FLinearColor(0.96, 1.0, 0.435);

	const FLinearColor Yellow = FLinearColor(1.0, 1.0, 0.0);
	const FLinearColor Marigold = FLinearColor(1.0, 0.705, 0.231);
	const FLinearColor Saffron = FLinearColor(1.0, 0.517, 0.0);
	const FLinearColor Carrot = FLinearColor(0.901, 0.494, 0.133);
	const FLinearColor Pumpkin = FLinearColor(1.0, 0.407, 0.250);
	const FLinearColor Tangerine = FLinearColor(1.0, 0.45, 0.376);

	const FLinearColor Vermillion = FLinearColor(0.886, 0.176, 0.090);
	const FLinearColor Tomato = FLinearColor(0.729, 0.192, 0.109);
	const FLinearColor Ruby = FLinearColor(0.803, 0.0, 0.054);
	const FLinearColor Red = FLinearColor(1.0, 0.0, 0.0);
	const FLinearColor Strawberry = FLinearColor(0.870, 0.196, 0.207);
	const FLinearColor Carmine = FLinearColor(0.694, 0.227, 0.227);

	const FLinearColor Fuchsia = FLinearColor(0.925, 0.0, 0.537);
	const FLinearColor Watermelon = FLinearColor(0.858, 0.317, 0.552);
	const FLinearColor Pink = FLinearColor(0.905, 0.498, 0.749);
	const FLinearColor Blush = FLinearColor(1.0, 0.635, 0.635);
	const FLinearColor BabyPink = FLinearColor(1.0, 0.9, 0.87);
	const FLinearColor Rose = FLinearColor(1.0, 0.839, 0.964);
	const FLinearColor Pearl = FLinearColor(0.984, 0.913, 0.972);

	const FLinearColor Cacao = FLinearColor(0.4, 0.24, 0.24);
	const FLinearColor Mauve = FLinearColor(0.611, 0.282, 0.458);
	const FLinearColor Brown = FLinearColor(0.556, 0.356, 0.247);
	const FLinearColor Latte = FLinearColor(0.592, 0.482, 0.423);
	const FLinearColor Beige = FLinearColor(0.792, 0.733, 0.635);

	FLinearColor Rainbow(float LoopDuration)
	{
		float Alpha = Math::Saturate(Math::Wrap(Time::GameTimeSeconds, 0.0, LoopDuration) / LoopDuration);
		float Hue = Math::Lerp(0.0, 255.95, Alpha);
		return FLinearColor::MakeFromHSV8(uint8(Hue), 255, 255);
	}

	void DrawTintedTransform(FVector Location, FRotator Rotation, FLinearColor ColorTint, float Scale = 500.0, float Alpha = 0.5)
	{
		const float Thickness = 15.0;
		const float ArrowSize = Thickness * 3.0;
		Debug::DrawDebugArrow(Location, Location + Rotation.ForwardVector * Scale, ArrowSize, Math::Lerp(ColorDebug::Red, ColorTint, Alpha), Thickness, 0.0, true);
		Debug::DrawDebugArrow(Location, Location + Rotation.RightVector * Scale, ArrowSize, Math::Lerp(ColorDebug::Green, ColorTint, Alpha), Thickness, 0.0, true);
		Debug::DrawDebugArrow(Location, Location + Rotation.UpVector * Scale, ArrowSize, Math::Lerp(ColorDebug::Blue, ColorTint, Alpha), Thickness, 0.0, true);
	}

	void DrawForward(FVector Location, FRotator Rotation, FLinearColor Color, float Scale = 500.0)
	{
		const float Thickness = 15.0;
		const float ArrowSize = Thickness * 3.0;
		Debug::DrawDebugArrow(Location, Location + Rotation.ForwardVector * Scale, ArrowSize, Color, Thickness, 0.0, true);
	}

	void DrawTintedCapsule(UHazeCapsuleCollisionComponent CapsuleComp, FLinearColor ColorTint, float Alpha = 0.5)
	{
		Debug::DrawDebugCapsule(CapsuleComp.WorldLocation, CapsuleComp.CapsuleHalfHeight, CapsuleComp.CapsuleRadius, CapsuleComp.WorldRotation, ColorTint * Alpha, 5.0, 0.0, true);
	}
};