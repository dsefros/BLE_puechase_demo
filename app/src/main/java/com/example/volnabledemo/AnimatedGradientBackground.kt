package com.example.volnabledemo

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

@Composable
fun AnimatedGradientBackground(
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "gradient_animation")

    // Анимация позиций для 5 больших кругов
    val circle1X by infiniteTransition.animateFloat(
        initialValue = -800f,
        targetValue = 2000f,
        animationSpec = infiniteRepeatable(
            animation = tween(30000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle1_x"
    )

    val circle1Y by infiniteTransition.animateFloat(
        initialValue = -600f,
        targetValue = 2600f,
        animationSpec = infiniteRepeatable(
            animation = tween(28000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle1_y"
    )

    val circle2X by infiniteTransition.animateFloat(
        initialValue = 1800f,
        targetValue = -1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(32000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle2_x"
    )

    val circle2Y by infiniteTransition.animateFloat(
        initialValue = 1000f,
        targetValue = 2800f,
        animationSpec = infiniteRepeatable(
            animation = tween(30000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle2_y"
    )

    val circle3X by infiniteTransition.animateFloat(
        initialValue = 600f,
        targetValue = 1600f,
        animationSpec = infiniteRepeatable(
            animation = tween(35000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle3_x"
    )

    val circle3Y by infiniteTransition.animateFloat(
        initialValue = 2000f,
        targetValue = -500f,
        animationSpec = infiniteRepeatable(
            animation = tween(33000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle3_y"
    )

    val circle4X by infiniteTransition.animateFloat(
        initialValue = 1200f,
        targetValue = 200f,
        animationSpec = infiniteRepeatable(
            animation = tween(38000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle4_x"
    )

    val circle4Y by infiniteTransition.animateFloat(
        initialValue = 500f,
        targetValue = 2300f,
        animationSpec = infiniteRepeatable(
            animation = tween(36000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle4_y"
    )

    val circle5X by infiniteTransition.animateFloat(
        initialValue = -200f,
        targetValue = 1400f,
        animationSpec = infiniteRepeatable(
            animation = tween(40000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle5_x"
    )

    val circle5Y by infiniteTransition.animateFloat(
        initialValue = 1300f,
        targetValue = 400f,
        animationSpec = infiniteRepeatable(
            animation = tween(38000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "circle5_y"
    )

    // Анимация размеров (пульсация)
    val size1 by infiniteTransition.animateFloat(
        initialValue = 1.2f,
        targetValue = 2.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(15000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size1"
    )

    val size2 by infiniteTransition.animateFloat(
        initialValue = 1.2f,
        targetValue = 2.2f,
        animationSpec = infiniteRepeatable(
            animation = tween(17000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size2"
    )

    val size3 by infiniteTransition.animateFloat(
        initialValue = 1.2f,
        targetValue = 2.1f,
        animationSpec = infiniteRepeatable(
            animation = tween(19000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size3"
    )

    val size4 by infiniteTransition.animateFloat(
        initialValue = 1.2f,
        targetValue = 1.9f,
        animationSpec = infiniteRepeatable(
            animation = tween(20000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size4"
    )

    val size5 by infiniteTransition.animateFloat(
        initialValue = 1.2f,
        targetValue = 2.0f,
        animationSpec = infiniteRepeatable(
            animation = tween(22000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "size5"
    )

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(Color.White)
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val center1 = Offset(circle1X, circle1Y)
            val center2 = Offset(circle2X, circle2Y)
            val center3 = Offset(circle3X, circle3Y)
            val center4 = Offset(circle4X, circle4Y)
            val center5 = Offset(circle5X, circle5Y)

            // Круг 1 - синий
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFF6AB0F5).copy(alpha = 0.65f),
                        Color(0xFF6AB0F5).copy(alpha = 0.28f),
                        Color.Transparent
                    ),
                    center = center1,
                    radius = 900f * size1
                ),
                radius = 900f * size1,
                center = center1
            )

            // Круг 2 - зеленый
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFF6FBF73).copy(alpha = 0.6f),
                        Color(0xFF6FBF73).copy(alpha = 0.25f),
                        Color.Transparent
                    ),
                    center = center2,
                    radius = 880f * size2
                ),
                radius = 880f * size2,
                center = center2
            )

            // Круг 3 - розовый
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFFF5B0B5).copy(alpha = 0.6f),
                        Color(0xFFF5B0B5).copy(alpha = 0.25f),
                        Color.Transparent
                    ),
                    center = center3,
                    radius = 950f * size3
                ),
                radius = 950f * size3,
                center = center3
            )

            // Круг 4 - персиковый
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFFFFC8A2).copy(alpha = 0.6f),
                        Color(0xFFFFC8A2).copy(alpha = 0.25f),
                        Color.Transparent
                    ),
                    center = center4,
                    radius = 850f * size4
                ),
                radius = 850f * size4,
                center = center4
            )

            // Круг 5 - лавандовый
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(
                        Color(0xFFC5C5F0).copy(alpha = 0.6f),
                        Color(0xFFC5C5F0).copy(alpha = 0.25f),
                        Color.Transparent
                    ),
                    center = center5,
                    radius = 920f * size5
                ),
                radius = 920f * size5,
                center = center5
            )
        }
    }
}